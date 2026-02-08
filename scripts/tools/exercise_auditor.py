#!/usr/bin/env python3
"""
運動動作分類審核自動化編排腳本

使用方式:
    python exercise_auditor.py pecs.csv --limit 5
    python exercise_auditor.py pecs.csv --start 10 --limit 10
    python exercise_auditor.py pecs.csv --all

依賴:
    pip install anthropic
"""

import argparse
import asyncio
import csv
import json
import os
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

# 專案根目錄
PROJECT_ROOT = Path(__file__).parent.parent.parent
AGENTS_DIR = PROJECT_ROOT / ".claude" / "agents"
REVIEW_DATA_DIR = PROJECT_ROOT / "scripts" / "review_data" / "by_muscle_grouped"


@dataclass
class ExerciseRecord:
    """動作資料記錄"""
    id: str
    original_name: str
    original_name_en: str
    suggested_name_zh: str
    suggested_name_en: str
    aliases: str
    movement_pattern: str
    ppl_tags: str
    primary_muscle: str
    secondary_muscles: str
    equipment: str
    mechanics: str
    unilateral: str
    difficulty: str
    is_explosive: str

    @classmethod
    def from_csv_row(cls, row: dict) -> "ExerciseRecord":
        return cls(
            id=row.get("id", ""),
            original_name=row.get("原名稱", ""),
            original_name_en=row.get("原英文名", ""),
            suggested_name_zh=row.get("建議中文名", ""),
            suggested_name_en=row.get("建議英文名", ""),
            aliases=row.get("別名（逗號分隔）", ""),
            movement_pattern=row.get("動作模式", ""),
            ppl_tags=row.get("PPL標籤", ""),
            primary_muscle=row.get("主動肌", ""),
            secondary_muscles=row.get("協同肌", ""),
            equipment=row.get("器材", ""),
            mechanics=row.get("複合/孤立", ""),
            unilateral=row.get("單邊", ""),
            difficulty=row.get("難度", ""),
            is_explosive=row.get("is_explosive", ""),
        )

    def to_prompt_data(self) -> str:
        """轉換為 Prompt 格式"""
        return f"""動作資料：
- ID: {self.id}
- 原名稱: {self.original_name}
- 原英文名: {self.original_name_en}
- 建議中文名: {self.suggested_name_zh}
- 建議英文名: {self.suggested_name_en}
- 別名: {self.aliases}
- 動作模式: {self.movement_pattern}
- PPL標籤: {self.ppl_tags}
- 主動肌: {self.primary_muscle}
- 協同肌: {self.secondary_muscles}
- 器材: {self.equipment}
- 複合/孤立: {self.mechanics}
- 單邊: {self.unilateral}
- 難度: {self.difficulty}
- 爆發力: {self.is_explosive}"""


def load_csv(file_path: Path, start: int = 0, limit: Optional[int] = None) -> list[ExerciseRecord]:
    """載入 CSV 檔案（支援 Big5 編碼）"""
    records = []

    # 嘗試不同編碼
    encodings = ["big5", "utf-8", "cp950", "gb2312"]

    for encoding in encodings:
        try:
            with open(file_path, "r", encoding=encoding) as f:
                reader = csv.DictReader(f)
                all_rows = list(reader)

                # 切片處理
                end = start + limit if limit else len(all_rows)
                selected_rows = all_rows[start:end]

                for row in selected_rows:
                    records.append(ExerciseRecord.from_csv_row(row))

                print(f"✓ 成功載入 {len(records)} 筆資料（編碼: {encoding}）")
                return records
        except UnicodeDecodeError:
            continue
        except Exception as e:
            print(f"✗ 讀取失敗 ({encoding}): {e}")
            continue

    raise ValueError(f"無法讀取檔案: {file_path}")


async def invoke_agent_cli(agent_name: str, exercise_data: str, timeout: int = 60) -> dict:
    """
    呼叫 Claude CLI Agent（無頭模式）

    使用 claude -p 進行非互動式呼叫
    """
    prompt = f"請審核以下動作資料，只輸出 JSON 格式結果，不要其他文字：\n\n{exercise_data}"

    # 構建 claude CLI 命令
    # 注意：實際 agent 名稱格式可能需要調整
    cmd = [
        "claude",
        "-p", prompt,
        "--output-format", "json",
        # "--agent", agent_name,  # 如果支援 agent 參數
    ]

    try:
        # 使用 asyncio 的 subprocess
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )

        stdout, stderr = await asyncio.wait_for(
            process.communicate(),
            timeout=timeout
        )

        output = stdout.decode("utf-8").strip()

        # 嘗試解析 JSON
        # Claude CLI 可能會輸出額外文字，需要提取 JSON 部分
        json_start = output.find("{")
        json_end = output.rfind("}") + 1

        if json_start >= 0 and json_end > json_start:
            json_str = output[json_start:json_end]
            return json.loads(json_str)
        else:
            return {"error": "No JSON found in output", "raw": output}

    except asyncio.TimeoutError:
        return {"error": f"Timeout after {timeout}s"}
    except json.JSONDecodeError as e:
        return {"error": f"JSON parse error: {e}", "raw": output}
    except FileNotFoundError:
        return {"error": "claude CLI not found. Please install Claude Code CLI."}
    except Exception as e:
        return {"error": str(e)}


async def invoke_agent_sdk(agent_name: str, exercise_data: str) -> dict:
    """
    使用 Anthropic SDK 直接呼叫 API（備選方案）

    需要設定 ANTHROPIC_API_KEY 環境變數
    """
    try:
        import anthropic
    except ImportError:
        return {"error": "anthropic package not installed. Run: pip install anthropic"}

    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        return {"error": "ANTHROPIC_API_KEY environment variable not set"}

    # 載入 Agent 定義
    agent_file = AGENTS_DIR / f"{agent_name}.json"
    if not agent_file.exists():
        return {"error": f"Agent definition not found: {agent_file}"}

    with open(agent_file, "r", encoding="utf-8") as f:
        agent_def = json.load(f)

    system_prompt = agent_def.get("prompt", "")

    client = anthropic.Anthropic(api_key=api_key)

    try:
        response = client.messages.create(
            model="claude-sonnet-4-20250514",  # 使用較快的模型
            max_tokens=1024,
            system=system_prompt,
            messages=[
                {
                    "role": "user",
                    "content": f"請審核以下動作資料，只輸出 JSON 格式結果：\n\n{exercise_data}"
                }
            ]
        )

        output = response.content[0].text

        # 提取 JSON
        json_start = output.find("{")
        json_end = output.rfind("}") + 1

        if json_start >= 0 and json_end > json_start:
            json_str = output[json_start:json_end]
            return json.loads(json_str)
        else:
            return {"error": "No JSON found", "raw": output}

    except Exception as e:
        return {"error": str(e)}


async def audit_single_exercise(record: ExerciseRecord, use_sdk: bool = True) -> dict:
    """
    審核單一動作（4 個 Agent 並行）
    """
    exercise_data = record.to_prompt_data()

    # 選擇呼叫方式
    invoke_func = invoke_agent_sdk if use_sdk else invoke_agent_cli

    # 並行呼叫 4 個 Agent
    tasks = [
        invoke_func("auditor-naming", exercise_data),
        invoke_func("auditor-classification", exercise_data),
        invoke_func("auditor-anatomy", exercise_data),
        invoke_func("auditor-attributes", exercise_data),
    ]

    results = await asyncio.gather(*tasks, return_exceptions=True)

    # 彙整結果
    audit_result = {
        "exercise_id": record.id,
        "exercise_name": record.suggested_name_zh,
        "agents": {
            "naming": results[0] if not isinstance(results[0], Exception) else {"error": str(results[0])},
            "classification": results[1] if not isinstance(results[1], Exception) else {"error": str(results[1])},
            "anatomy": results[2] if not isinstance(results[2], Exception) else {"error": str(results[2])},
            "attributes": results[3] if not isinstance(results[3], Exception) else {"error": str(results[3])},
        },
        "overall_status": "OK"
    }

    # 計算整體狀態
    for agent_result in audit_result["agents"].values():
        if isinstance(agent_result, dict):
            if "error" in agent_result:
                audit_result["overall_status"] = "ERROR"
                break
            # 檢查各欄位狀態
            for key, value in agent_result.items():
                if isinstance(value, dict) and value.get("status") == "ERROR":
                    audit_result["overall_status"] = "ERROR"
                    break
                elif isinstance(value, dict) and value.get("status") == "WARN":
                    if audit_result["overall_status"] == "OK":
                        audit_result["overall_status"] = "WARN"

    return audit_result


async def audit_batch(records: list[ExerciseRecord], concurrency: int = 2, use_sdk: bool = True) -> list[dict]:
    """
    批次審核（控制並發數）
    """
    semaphore = asyncio.Semaphore(concurrency)

    async def audit_with_semaphore(record: ExerciseRecord) -> dict:
        async with semaphore:
            print(f"  審核中: {record.suggested_name_zh[:20]}...")
            result = await audit_single_exercise(record, use_sdk)
            status_icon = {"OK": "✓", "WARN": "⚠", "ERROR": "✗"}.get(result["overall_status"], "?")
            print(f"  {status_icon} 完成: {record.suggested_name_zh[:20]}")
            return result

    tasks = [audit_with_semaphore(record) for record in records]
    return await asyncio.gather(*tasks)


def generate_report(results: list[dict], output_path: Optional[Path] = None) -> str:
    """生成審核報告"""
    report_lines = [
        "=" * 60,
        "運動動作分類審核報告",
        "=" * 60,
        "",
        f"總審核筆數: {len(results)}",
        f"通過 (OK): {sum(1 for r in results if r['overall_status'] == 'OK')}",
        f"警告 (WARN): {sum(1 for r in results if r['overall_status'] == 'WARN')}",
        f"錯誤 (ERROR): {sum(1 for r in results if r['overall_status'] == 'ERROR')}",
        "",
        "-" * 60,
        "詳細結果",
        "-" * 60,
    ]

    for result in results:
        status_icon = {"OK": "✓", "WARN": "⚠", "ERROR": "✗"}.get(result["overall_status"], "?")
        report_lines.append(f"\n{status_icon} [{result['exercise_id'][:8]}...] {result['exercise_name']}")

        if result["overall_status"] != "OK":
            for agent_name, agent_result in result["agents"].items():
                if isinstance(agent_result, dict):
                    if "error" in agent_result:
                        report_lines.append(f"   {agent_name}: ERROR - {agent_result['error']}")
                    elif "summary" in agent_result:
                        report_lines.append(f"   {agent_name}: {agent_result['summary']}")

    report = "\n".join(report_lines)

    if output_path:
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(report)
        print(f"\n報告已儲存: {output_path}")

    return report


def main():
    parser = argparse.ArgumentParser(description="運動動作分類審核自動化工具")
    parser.add_argument("csv_file", help="CSV 檔案名稱（位於 review_data/by_muscle_grouped/）")
    parser.add_argument("--start", type=int, default=0, help="起始行數（0-indexed）")
    parser.add_argument("--limit", type=int, help="審核筆數限制")
    parser.add_argument("--all", action="store_true", help="審核所有資料")
    parser.add_argument("--concurrency", type=int, default=2, help="並發數（預設 2）")
    parser.add_argument("--use-cli", action="store_true", help="使用 CLI 模式（預設使用 SDK）")
    parser.add_argument("--output", type=str, help="輸出報告檔案路徑")
    parser.add_argument("--json", action="store_true", help="輸出 JSON 格式")

    args = parser.parse_args()

    # 確定 CSV 路徑
    csv_path = REVIEW_DATA_DIR / args.csv_file
    if not csv_path.exists():
        # 嘗試加上 .csv 副檔名
        csv_path = REVIEW_DATA_DIR / f"{args.csv_file}.csv"

    if not csv_path.exists():
        print(f"✗ 找不到檔案: {csv_path}")
        print(f"  可用檔案: {', '.join(f.name for f in REVIEW_DATA_DIR.glob('*.csv'))}")
        sys.exit(1)

    # 設定限制
    limit = None if args.all else (args.limit or 3)

    print(f"=" * 60)
    print(f"運動動作分類審核工具")
    print(f"=" * 60)
    print(f"CSV 檔案: {csv_path.name}")
    print(f"起始位置: {args.start}")
    print(f"審核筆數: {'全部' if args.all else limit}")
    print(f"並發數: {args.concurrency}")
    print(f"呼叫模式: {'CLI' if args.use_cli else 'SDK'}")
    print()

    # 載入資料
    try:
        records = load_csv(csv_path, start=args.start, limit=limit)
    except Exception as e:
        print(f"✗ 載入失敗: {e}")
        sys.exit(1)

    if not records:
        print("沒有資料需要審核")
        sys.exit(0)

    # 執行審核
    print(f"\n開始審核 {len(records)} 筆資料...")
    print("-" * 40)

    use_sdk = not args.use_cli
    results = asyncio.run(audit_batch(records, args.concurrency, use_sdk))

    # 輸出結果
    if args.json:
        output = json.dumps(results, ensure_ascii=False, indent=2)
        if args.output:
            with open(args.output, "w", encoding="utf-8") as f:
                f.write(output)
            print(f"\nJSON 結果已儲存: {args.output}")
        else:
            print(output)
    else:
        output_path = Path(args.output) if args.output else None
        report = generate_report(results, output_path)
        print(report)


if __name__ == "__main__":
    main()
