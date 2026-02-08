#!/usr/bin/env python3
"""
運動動作審核腳本 - 使用 Claude Code CLI

使用方式:
    # 審核並產生建議
    python3 exercise_auditor_cli.py pecs.csv --start 75 --limit 3

    # 審核後直接套用修改
    python3 exercise_auditor_cli.py pecs.csv --start 75 --limit 3 --apply
"""

import argparse
import csv
import json
import subprocess
import sys
from pathlib import Path
from typing import Optional

PROJECT_ROOT = Path(__file__).parent.parent.parent
REVIEW_DATA_DIR = PROJECT_ROOT / "scripts" / "review_data" / "by_muscle_grouped"

# CSV 欄位對應
FIELD_MAPPING = {
    "建議中文名": "建議中文名",
    "建議英文名": "建議英文名",
    "別名": "別名（逗號分隔）",
    "動作模式": "動作模式",
    "PPL標籤": "PPL標籤",
    "主動肌": "主動肌",
    "協同肌": "協同肌",
    "器材": "器材",
    "複合/孤立": "複合/孤立",
    "單邊": "單邊",
    "難度": "難度",
    "is_explosive": "is_explosive",
}

# ============================================================
# 完整審核規則
# ============================================================

AUDIT_PROMPT = """你是運動動作分類審核專家。請根據以下規則審核動作資料，並以 JSON 格式回傳結果。

═══════════════════════════════════════════════════════════════
1. SEE 命名格式（Specification - Equipment - Exercise）
═══════════════════════════════════════════════════════════════

結構：[規格] + [器材] + [動作]
規格順序：[單雙側] → [姿勢] → [握法] → [角度] → [器材] → [動作]

【規格類型】
| 類型 | 中文 | 英文 |
|------|------|------|
| 單雙側 | 單手、單腳、交替 | Single Arm, Single Leg, Alternating |
| 姿勢 | 站姿、坐姿、仰臥、俯臥、俯身、跪姿、懸垂 | Standing, Seated, Lying/Supine, Prone, Bent Over, Kneeling, Hanging |
| 握法 | 寬握、窄握、反握、正握、中立握 | Wide Grip, Close/Narrow Grip, Reverse/Underhand, Overhand, Neutral Grip |
| 角度 | 上斜、下斜、平板 | Incline, Decline, Flat |

【省略規則】
- 雙手/雙腳（預設）→ 省略
- 站姿（部分動作預設）→ 可省略
- 正握（部分動作預設）→ 可省略
- 平板（臥推預設）→ 可省略

【特殊規則】
- ⭐ Single Arm 動作省略「Narrow Grip」（單手沒有雙手間距概念）
- ⭐ Wide Grip 需明確標示（寬握改變力學）
- 坐姿 Seated 必須保留，不可省略

【姿勢標準化】
| 中文 | 英文 | 定義 |
|------|------|------|
| 半跪姿 | Half Kneeling | 單膝跪地，另一腳踩地 |
| 高跪姿 | Tall Kneeling | 雙膝跪地 |
| 俯身 | Bent Over | 髖關節屈曲，軀幹前傾 |
| 弓箭步 | Lunge Stance | 前後腳分開站立（靜態）|

═══════════════════════════════════════════════════════════════
2. 別名規則
═══════════════════════════════════════════════════════════════

【格式】中英文都要有，逗號分隔
【內容】只包含「角度 + 器材 + 動作」
- ⭐ 省略單雙側/交替/握距
- 包含俚語、縮寫、舊名稱

【必要別名】
- 中文別名：至少 1 個（省略規格後的常見中文叫法）
- 英文別名：至少 1 個（省略規格後的常見英文叫法）
- 常見縮寫（如 OHP, BTN, HSPU 等，如果有的話）

【範例】
- 坐姿啞鈴肩推 → 別名: 啞鈴肩推, Dumbbell Shoulder Press
- 站姿槓鈴肩推 → 別名: 槓鈴肩推, Barbell Shoulder Press, OHP, Military Press
- 交替啞鈴前平舉 → 別名: 啞鈴前平舉, Dumbbell Front Raise

═══════════════════════════════════════════════════════════════
3. 動作模式（Movement Pattern）
═══════════════════════════════════════════════════════════════

【有效值】
頂層：push, pull, squat, hinge, lunge, core, carry, cardio, mobility
- Push 子類：horizontal_push, vertical_push, isolation_push
- Pull 子類：horizontal_pull, vertical_pull, isolation_pull
- Squat 子類：isolation_squat
- Hinge 子類：isolation_hinge
- Core 子類：anti_extension, anti_rotation, anti_lateral, flexion, rotation

【孤立動作歸類規則】⭐
- 三頭伸展、飛鳥 → isolation_push（Push 子類）
- 二頭彎舉、反向飛鳥 → isolation_pull（Pull 子類）
- 腿伸展 → isolation_squat（Squat 子類）
- 腿彎舉、髖外展 → isolation_hinge（Hinge 子類）

【可接受的複合/舊版值】（不需要修改，不要建議轉換）
isolation_upper, isolation_lower, power, plyometric,
core_rotation, core_anti_rotation, core_anti_extension,
core_anti_lateral, core_anti_lateral_flexion, core_flexion,
core_anti_flexion, core_abduction,
anti_lateral_flexion, anti_flexion, lateral_flexion,
rotation (external), rotation (internal),
olympic, olympic_lift, legs

【爆發力動作】
- 爆發力動作（跳躍、拋擲、抓舉、挺舉等）應標記 is_explosive=TRUE

═══════════════════════════════════════════════════════════════
4. PPL 標籤（Split Tags）
═══════════════════════════════════════════════════════════════

【有效值】push, pull, legs, upper, lower, core, shoulders, cardio, mobility

【標籤定義】
- Push: 胸、肩前/中束、三頭
- Pull: 背、二頭、肩後束
- Legs: 下肢
- Upper: 上肢動作
- Lower: 下肢動作
- Core: 核心動作

【特殊規則】⭐
| 動作類型 | PPL 標籤 | 理由 |
|----------|----------|------|
| 後三角肌孤立動作 | Pull | 功能上與划船/引體類似 |
| 硬舉 | Pull + Legs | 同時涉及拉與下肢 |
| 肩推 | Push | 垂直推 |
| 側平舉 | Push | 三角肌發力 |

═══════════════════════════════════════════════════════════════
5. 主動肌（25 個有效值）
═══════════════════════════════════════════════════════════════

【胸】pec_major_clavicular（上胸）, pec_major_sternal（中下胸）, pec_minor, serratus_anterior
【背】lats, traps, rhomboids, erector_spinae, teres_major
【肩】front_delts, side_delts, rear_delts, rotator_cuff
【手】biceps, triceps, brachialis, forearms
【腿】quads, hamstrings, glutes, adductors, calves, hip_flexors, tibialis_anterior
【核心】abs, obliques

【填寫規則】⭐
- 只填一個，不可多選
- 不加括號

═══════════════════════════════════════════════════════════════
6. 協同肌
═══════════════════════════════════════════════════════════════

- 可多選，逗號分隔
- 使用與主動肌相同的 25 個有效值
- 非正式別名（如 core, upper_chest, chest, back 等）必須轉換為正確的肌群 ID
  例：core → abs 或 obliques, upper_chest → pec_major_clavicular, chest → pec_major_sternal

═══════════════════════════════════════════════════════════════
7. 器材（19 種）
═══════════════════════════════════════════════════════════════

barbell, dumbbell, kettlebell, cable, machine, bodyweight, smith_machine, suspension, resistance_band, landmine, ez_bar, medicine_ball, battle_rope, sled, vipr, foam_roller, cardio_machine, ab_wheel, log_bar

═══════════════════════════════════════════════════════════════
8. 其他欄位
═══════════════════════════════════════════════════════════════

【複合/孤立】compound（多關節）/ isolation（單關節）
【單邊】TRUE（單手/單腳/交替）/ FALSE
【難度】beginner / intermediate / advanced
【is_explosive】TRUE（爆發力）/ FALSE

═══════════════════════════════════════════════════════════════
請審核以下動作
═══════════════════════════════════════════════════════════════

{exercise_data}

═══════════════════════════════════════════════════════════════
輸出格式（必須是有效的 JSON）
═══════════════════════════════════════════════════════════════

請回傳以下 JSON 格式，每個欄位都要列出：
- "original": 原始值
- "suggested": 建議值（如果需要修改）或 null（如果不需要修改）
- "reason": 修改原因（如果需要修改）或 null

```json
{{
  "建議中文名": {{"original": "...", "suggested": "..." 或 null, "reason": "..." 或 null}},
  "建議英文名": {{"original": "...", "suggested": "..." 或 null, "reason": "..." 或 null}},
  "別名": {{"original": "...", "suggested": "..." 或 null, "reason": "..." 或 null}},
  "動作模式": {{"original": "...", "suggested": "..." 或 null, "reason": "..." 或 null}},
  "PPL標籤": {{"original": "...", "suggested": "..." 或 null, "reason": "..." 或 null}},
  "主動肌": {{"original": "...", "suggested": "..." 或 null, "reason": "..." 或 null}},
  "協同肌": {{"original": "...", "suggested": "..." 或 null, "reason": "..." 或 null}},
  "器材": {{"original": "...", "suggested": "..." 或 null, "reason": "..." 或 null}},
  "複合/孤立": {{"original": "...", "suggested": "..." 或 null, "reason": "..." 或 null}},
  "單邊": {{"original": "...", "suggested": "..." 或 null, "reason": "..." 或 null}},
  "難度": {{"original": "...", "suggested": "..." 或 null, "reason": "..." 或 null}},
  "is_explosive": {{"original": "...", "suggested": "..." 或 null, "reason": "..." 或 null}},
  "summary": "整體評估摘要"
}}
```

只輸出 JSON，不要其他文字。
"""


def load_csv(file_path: Path) -> tuple[list[dict], list[str]]:
    """載入 CSV，回傳 (rows, fieldnames)"""
    encodings = ["big5", "utf-8", "cp950"]
    for encoding in encodings:
        try:
            with open(file_path, "r", encoding=encoding) as f:
                reader = csv.DictReader(f)
                fieldnames = reader.fieldnames
                rows = list(reader)
                return rows, fieldnames, encoding
        except UnicodeDecodeError:
            continue
    raise ValueError(f"無法讀取: {file_path}")


def save_csv(file_path: Path, rows: list[dict], fieldnames: list[str], encoding: str):
    """儲存 CSV"""
    with open(file_path, "w", encoding=encoding, newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def format_record(row: dict) -> str:
    """格式化為審核用文字"""
    return f"""【原始資料】
- ID: {row.get('id', '')}
- 原名稱: {row.get('原名稱', '')}
- 原英文名: {row.get('原英文名', '')}

【待審核欄位】
1. 建議中文名: {row.get('建議中文名', '')}
2. 建議英文名: {row.get('建議英文名', '')}
3. 別名: {row.get('別名（逗號分隔）', '')}
4. 動作模式: {row.get('動作模式', '')}
5. PPL標籤: {row.get('PPL標籤', '')}
6. 主動肌: {row.get('主動肌', '')}
7. 協同肌: {row.get('協同肌', '')}
8. 器材: {row.get('器材', '')}
9. 複合/孤立: {row.get('複合/孤立', '')}
10. 單邊: {row.get('單邊', '')}
11. 難度: {row.get('難度', '')}
12. is_explosive: {row.get('is_explosive', '')}"""


def audit_with_cli(record_text: str, timeout: int = 120) -> Optional[dict]:
    """使用 Claude Code CLI 審核，回傳 JSON"""
    prompt = AUDIT_PROMPT.format(exercise_data=record_text)

    try:
        result = subprocess.run(
            ["claude", "-p", prompt],
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd=PROJECT_ROOT,
        )

        if result.returncode != 0:
            print(f"錯誤: {result.stderr}")
            return None

        output = result.stdout.strip()

        # 提取 JSON
        json_start = output.find("{")
        json_end = output.rfind("}") + 1
        if json_start >= 0 and json_end > json_start:
            json_str = output[json_start:json_end]
            return json.loads(json_str)
        else:
            print(f"無法解析 JSON: {output[:200]}")
            return None

    except subprocess.TimeoutExpired:
        print(f"逾時（{timeout}秒）")
        return None
    except json.JSONDecodeError as e:
        print(f"JSON 解析錯誤: {e}")
        return None
    except Exception as e:
        print(f"錯誤: {e}")
        return None


def display_audit_result(row: dict, audit_result: dict, row_index: int):
    """顯示審核結果（垂直格式，完整顯示每個欄位）"""
    name_zh = row.get('建議中文名', '')
    orig_name = row.get('原名稱', '')
    orig_name_en = row.get('原英文名', '')

    print(f"\n{'='*70}")
    print(f"[{row_index}] {name_zh}")
    print(f"{'='*70}")
    print(f"原名稱: {orig_name}")
    print(f"原英文名: {orig_name_en}")
    print(f"{'='*70}")

    has_changes = False
    changes_count = 0

    field_num = 1
    for field_name in FIELD_MAPPING.keys():
        field_data = audit_result.get(field_name, {})
        if not isinstance(field_data, dict):
            print(f"\n{field_num:2}. {field_name}")
            print(f"   ❓ 無資料")
            field_num += 1
            continue

        original = field_data.get("original", "")
        suggested = field_data.get("suggested")
        reason = field_data.get("reason", "")

        print(f"\n{field_num:2}. {field_name}")
        print(f"   原始: {original}")

        if suggested is not None:
            has_changes = True
            changes_count += 1
            print(f"   ⚠ 建議: {suggested}")
            if reason:
                print(f"   原因: {reason}")
        else:
            print(f"   ✓ 不需修改")

        field_num += 1

    summary = audit_result.get("summary", "")
    print(f"\n{'='*70}")
    print(f"📋 摘要: {summary}")
    print(f"📊 需修改: {changes_count} / 12 欄位")
    print(f"{'='*70}")

    return has_changes


def apply_changes(row: dict, audit_result: dict) -> dict:
    """套用審核建議到 row"""
    updated_row = row.copy()

    for field_name, csv_field in FIELD_MAPPING.items():
        field_data = audit_result.get(field_name, {})
        if isinstance(field_data, dict):
            suggested = field_data.get("suggested")
            if suggested is not None:
                updated_row[csv_field] = suggested

    return updated_row


def main():
    parser = argparse.ArgumentParser(description="運動動作審核（CLI 版）")
    parser.add_argument("csv_file", help="CSV 檔案名稱")
    parser.add_argument("--start", type=int, default=0, help="起始行（0-indexed）")
    parser.add_argument("--limit", type=int, default=3, help="審核筆數")
    parser.add_argument("--apply", action="store_true", help="審核後直接套用修改到 CSV")
    parser.add_argument("--dry-run", action="store_true", help="只顯示資料，不審核")
    args = parser.parse_args()

    # CSV 路徑
    csv_path = REVIEW_DATA_DIR / args.csv_file
    if not csv_path.exists():
        csv_path = REVIEW_DATA_DIR / f"{args.csv_file}.csv"
    if not csv_path.exists():
        print(f"✗ 找不到: {csv_path}")
        sys.exit(1)

    print(f"{'='*70}")
    print(f"運動動作審核 - Claude Code CLI")
    print(f"{'='*70}")
    print(f"檔案: {csv_path.name}")
    print(f"範圍: 第 {args.start + 1} ~ {args.start + args.limit} 筆")
    if args.apply:
        print(f"⚠️  套用模式：審核後將直接修改 CSV")
    print()

    # 載入 CSV
    all_rows, fieldnames, encoding = load_csv(csv_path)
    print(f"✓ 載入 {len(all_rows)} 筆（編碼: {encoding}）")

    # 選取要審核的範圍
    end_index = min(args.start + args.limit, len(all_rows))
    selected_indices = range(args.start, end_index)

    if args.dry_run:
        for i in selected_indices:
            row = all_rows[i]
            print(f"\n[{i+1}] {row.get('建議中文名', '')}")
            print(format_record(row))
        return

    # 審核並收集結果
    audit_results = []
    modified_count = 0

    for i in selected_indices:
        row = all_rows[i]
        print(f"\n審核中 [{i+1}/{len(all_rows)}]...")

        record_text = format_record(row)
        result = audit_with_cli(record_text)

        if result:
            has_changes = display_audit_result(row, result, i + 1)
            audit_results.append((i, row, result, has_changes))

            if has_changes:
                modified_count += 1

                if args.apply:
                    all_rows[i] = apply_changes(row, result)
                    print("✅ 已套用修改")

    # 統計
    print(f"\n{'='*70}")
    print("審核完成")
    print(f"{'='*70}")
    print(f"審核筆數: {len(audit_results)}")
    print(f"需修改: {modified_count}")

    # 儲存 CSV
    if args.apply and modified_count > 0:
        try:
            save_csv(csv_path, all_rows, fieldnames, encoding)
            print(f"✅ 已儲存修改到 {csv_path.name}")
        except PermissionError:
            # 如果原檔案被鎖定，儲存到新檔案
            backup_path = csv_path.with_suffix(".reviewed.csv")
            save_csv(backup_path, all_rows, fieldnames, encoding)
            print(f"⚠️ 原檔案被鎖定，已儲存到: {backup_path.name}")
            print(f"   請關閉 Excel 後，手動將 {backup_path.name} 覆蓋 {csv_path.name}")
    elif modified_count > 0 and not args.apply:
        print(f"\n💡 如要套用修改，請加上 --apply 參數：")
        print(f"   python3 {Path(__file__).name} {args.csv_file} --start {args.start} --limit {args.limit} --apply")


if __name__ == "__main__":
    main()
