#!/usr/bin/env python3
"""
簡化版運動動作審核腳本 - 單一 Agent 模式

使用方式:
    # 設定 API Key
    export ANTHROPIC_API_KEY=your_key_here

    # 審核單筆資料
    python exercise_auditor_simple.py pecs.csv --limit 1

    # 審核前 5 筆
    python exercise_auditor_simple.py pecs.csv --limit 5
"""

import argparse
import csv
import json
import os
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent.parent
REVIEW_DATA_DIR = PROJECT_ROOT / "scripts" / "review_data" / "by_muscle_grouped"
REFERENCE_DATA_DIR = PROJECT_ROOT / "scripts" / "reference_data"


SYSTEM_PROMPT = """你是運動動作分類審核專家。你的任務是審核動作資料的 12 個欄位是否正確。

## 審核標準

### 1. 命名（SEE 格式）
格式：[規格] + [器材] + [動作]
規格順序：[單雙側] → [姿勢] → [握法] → [角度]

### 2. 動作模式（有效值）
頂層：push, pull, squat, hinge, lunge, core, carry, cardio, mobility
子層：horizontal_push, vertical_push, isolation_push, horizontal_pull, vertical_pull, isolation_pull, isolation_squat, isolation_hinge, anti_extension, anti_rotation, anti_lateral, flexion, rotation

### 3. PPL 標籤
push（胸/肩/三頭）, pull（背/二頭）, legs（下肢）, upper, lower, core

### 4. 主動肌（25 個有效值）
胸：pec_major_clavicular, pec_major_sternal, pec_minor, serratus_anterior
背：lats, traps, rhomboids, erector_spinae, teres_major
肩：front_delts, side_delts, rear_delts, rotator_cuff
手：biceps, triceps, brachialis, forearms
腿：quads, hamstrings, glutes, adductors, calves, hip_flexors, tibialis_anterior
核心：abs, obliques

### 5. 器材（19 種）
barbell, dumbbell, kettlebell, cable, machine, bodyweight, smith_machine, suspension, resistance_band, landmine, ez_bar, medicine_ball, battle_rope, sled, vipr, foam_roller, cardio_machine, ab_wheel, log_bar

### 6. 其他
- 複合/孤立：compound（多關節）/ isolation（單關節）
- 單邊：TRUE（單手/單腳/交替）/ FALSE
- 難度：beginner / intermediate / advanced
- is_explosive：TRUE（爆發力）/ FALSE

## 輸出格式
必須輸出 JSON，格式如下：
```json
{
  "exercise_id": "ID",
  "status": "OK|WARN|ERROR",
  "issues": [
    {"field": "欄位名", "severity": "WARN|ERROR", "message": "問題描述", "suggestion": "建議修改"}
  ],
  "summary": "簡短總結"
}
```

如果沒有問題，issues 為空陣列，status 為 "OK"。"""


def load_csv(file_path: Path, start: int = 0, limit: int = 5) -> list[dict]:
    """載入 CSV"""
    encodings = ["big5", "utf-8", "cp950"]
    for encoding in encodings:
        try:
            with open(file_path, "r", encoding=encoding) as f:
                reader = csv.DictReader(f)
                rows = list(reader)[start:start + limit]
                print(f"✓ 載入 {len(rows)} 筆（編碼: {encoding}）")
                return rows
        except UnicodeDecodeError:
            continue
    raise ValueError(f"無法讀取: {file_path}")


def format_record(row: dict) -> str:
    """格式化為審核用文字"""
    return f"""動作資料：
- ID: {row.get('id', '')}
- 原名稱: {row.get('原名稱', '')}
- 建議中文名: {row.get('建議中文名', '')}
- 建議英文名: {row.get('建議英文名', '')}
- 別名: {row.get('別名（逗號分隔）', '')}
- 動作模式: {row.get('動作模式', '')}
- PPL標籤: {row.get('PPL標籤', '')}
- 主動肌: {row.get('主動肌', '')}
- 協同肌: {row.get('協同肌', '')}
- 器材: {row.get('器材', '')}
- 複合/孤立: {row.get('複合/孤立', '')}
- 單邊: {row.get('單邊', '')}
- 難度: {row.get('難度', '')}
- is_explosive: {row.get('is_explosive', '')}"""


def audit_with_sdk(record_text: str) -> dict:
    """使用 Anthropic SDK 審核"""
    try:
        import anthropic
    except ImportError:
        return {"error": "請安裝 anthropic: pip install anthropic"}

    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        return {"error": "請設定 ANTHROPIC_API_KEY 環境變數"}

    client = anthropic.Anthropic(api_key=api_key)

    response = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=1024,
        system=SYSTEM_PROMPT,
        messages=[{"role": "user", "content": f"請審核以下動作：\n\n{record_text}"}]
    )

    output = response.content[0].text

    # 提取 JSON
    json_start = output.find("{")
    json_end = output.rfind("}") + 1
    if json_start >= 0 and json_end > json_start:
        return json.loads(output[json_start:json_end])
    return {"error": "無法解析輸出", "raw": output}


def main():
    parser = argparse.ArgumentParser(description="簡化版運動動作審核")
    parser.add_argument("csv_file", help="CSV 檔案名稱")
    parser.add_argument("--start", type=int, default=0, help="起始行")
    parser.add_argument("--limit", type=int, default=3, help="審核筆數")
    parser.add_argument("--dry-run", action="store_true", help="只顯示資料，不呼叫 API")
    args = parser.parse_args()

    # 確定 CSV 路徑
    csv_path = REVIEW_DATA_DIR / args.csv_file
    if not csv_path.exists():
        csv_path = REVIEW_DATA_DIR / f"{args.csv_file}.csv"
    if not csv_path.exists():
        print(f"✗ 找不到: {csv_path}")
        sys.exit(1)

    print(f"{'='*50}")
    print(f"運動動作審核 - 簡化版")
    print(f"{'='*50}")
    print(f"檔案: {csv_path.name}")
    print(f"範圍: {args.start} ~ {args.start + args.limit - 1}")
    print()

    records = load_csv(csv_path, args.start, args.limit)

    results = []
    for i, row in enumerate(records):
        print(f"\n[{i+1}/{len(records)}] 審核: {row.get('建議中文名', '')[:25]}...")
        record_text = format_record(row)

        if args.dry_run:
            print(record_text)
            print("-" * 40)
            continue

        result = audit_with_sdk(record_text)
        results.append(result)

        if "error" in result:
            print(f"  ✗ 錯誤: {result['error']}")
        else:
            status = result.get("status", "?")
            icon = {"OK": "✓", "WARN": "⚠", "ERROR": "✗"}.get(status, "?")
            print(f"  {icon} {status}: {result.get('summary', '')}")

            if result.get("issues"):
                for issue in result["issues"]:
                    print(f"    - [{issue['severity']}] {issue['field']}: {issue['message']}")

    if not args.dry_run and results:
        # 統計
        print(f"\n{'='*50}")
        print("審核結果統計")
        print(f"{'='*50}")
        ok = sum(1 for r in results if r.get("status") == "OK")
        warn = sum(1 for r in results if r.get("status") == "WARN")
        error = sum(1 for r in results if r.get("status") == "ERROR" or "error" in r)
        print(f"✓ OK: {ok}")
        print(f"⚠ WARN: {warn}")
        print(f"✗ ERROR: {error}")


if __name__ == "__main__":
    main()
