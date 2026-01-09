#!/usr/bin/env python3
"""
驗證 daily_workout_summary 數據正確性

檢查項目：
1. total_sets 是否等於實際 set.completed = true 的組數
2. total_volume 是否等於實際 weight * reps 總和
3. workout_count 是否正確
4. partial_workout_count 是否正確
"""

import os
import json
from datetime import datetime
from dotenv import load_dotenv
from supabase import create_client

# 載入環境變數
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ 請設置 SUPABASE_URL 和 SUPABASE_SERVICE_ROLE_KEY 環境變數")
    exit(1)

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)


def get_daily_workout_summary():
    """獲取 daily_workout_summary 表數據"""
    response = supabase.table("daily_workout_summary").select("*").order("date", desc=True).limit(50).execute()
    return response.data


def get_workout_plans():
    """獲取 workout_plans 表數據"""
    response = supabase.table("workout_plans").select("*").execute()
    return response.data


def calculate_expected_stats(workout_plans):
    """根據 workout_plans 計算預期的統計數據"""
    stats = {}  # {(user_id, date): {...}}
    
    for wp in workout_plans:
        user_id = wp.get("trainee_id")
        exercises = wp.get("exercises", [])
        completed = wp.get("completed", False)
        
        # 決定日期
        date_str = wp.get("completed_date") or wp.get("scheduled_date") or wp.get("updated_at")
        if date_str:
            # 只取日期部分
            date = date_str[:10]
        else:
            continue
        
        key = (user_id, date)
        
        if key not in stats:
            stats[key] = {
                "user_id": user_id,
                "date": date,
                "expected_total_sets": 0,
                "expected_total_volume": 0.0,
                "workout_ids_with_completed_sets": set(),
                "workout_completed_true_count": 0,
                "workout_partial_count": 0,
            }
        
        has_completed_set = False
        
        for exercise in exercises:
            sets = exercise.get("sets", [])
            for s in sets:
                is_completed = s.get("completed", False)
                if is_completed is True or str(is_completed).lower() == "true":
                    has_completed_set = True
                    stats[key]["expected_total_sets"] += 1
                    
                    weight = float(s.get("weight", 0) or 0)
                    reps = int(s.get("reps", 0) or 0)
                    stats[key]["expected_total_volume"] += weight * reps
        
        if has_completed_set:
            stats[key]["workout_ids_with_completed_sets"].add(wp.get("id"))
        
        if completed is True or str(completed).lower() == "true":
            stats[key]["workout_completed_true_count"] += 1
        elif has_completed_set:
            stats[key]["workout_partial_count"] += 1
    
    # 計算 workout_count
    for key, data in stats.items():
        data["expected_workout_count"] = len(data["workout_ids_with_completed_sets"])
        del data["workout_ids_with_completed_sets"]  # 移除 set 因為無法 JSON 序列化
    
    return stats


def compare_stats(summary_data, expected_stats):
    """比較實際數據和預期數據"""
    errors = []
    matches = 0
    
    for row in summary_data:
        user_id = row.get("user_id")
        date = row.get("date")
        key = (user_id, date)
        
        if key not in expected_stats:
            errors.append({
                "type": "extra_row",
                "user_id": user_id,
                "date": date,
                "message": "彙總表有此記錄，但 workout_plans 沒有對應數據"
            })
            continue
        
        expected = expected_stats[key]
        
        # 比較 total_sets
        actual_sets = row.get("total_sets", 0)
        expected_sets = expected["expected_total_sets"]
        if actual_sets != expected_sets:
            errors.append({
                "type": "total_sets_mismatch",
                "user_id": user_id,
                "date": date,
                "actual": actual_sets,
                "expected": expected_sets,
            })
        
        # 比較 total_volume
        actual_volume = float(row.get("total_volume", 0))
        expected_volume = expected["expected_total_volume"]
        if abs(actual_volume - expected_volume) > 0.01:
            errors.append({
                "type": "total_volume_mismatch",
                "user_id": user_id,
                "date": date,
                "actual": actual_volume,
                "expected": expected_volume,
            })
        
        # 比較 workout_count
        actual_workout_count = row.get("workout_count", 0)
        expected_workout_count = expected["expected_workout_count"]
        if actual_workout_count != expected_workout_count:
            errors.append({
                "type": "workout_count_mismatch",
                "user_id": user_id,
                "date": date,
                "actual": actual_workout_count,
                "expected": expected_workout_count,
            })
        
        # 比較 partial_workout_count
        actual_partial = row.get("partial_workout_count", 0)
        expected_partial = expected["workout_partial_count"]
        if actual_partial != expected_partial:
            errors.append({
                "type": "partial_workout_count_mismatch",
                "user_id": user_id,
                "date": date,
                "actual": actual_partial,
                "expected": expected_partial,
            })
        
        # 比較 completed_workout_count
        actual_completed = row.get("completed_workout_count", 0)
        expected_completed = expected["workout_completed_true_count"]
        if actual_completed != expected_completed:
            errors.append({
                "type": "completed_workout_count_mismatch",
                "user_id": user_id,
                "date": date,
                "actual": actual_completed,
                "expected": expected_completed,
            })
        
        if all([
            actual_sets == expected_sets,
            abs(actual_volume - expected_volume) <= 0.01,
            actual_workout_count == expected_workout_count,
        ]):
            matches += 1
    
    return errors, matches


def main():
    print("=" * 60)
    print("[VERIFY] daily_workout_summary data validation")
    print("=" * 60)
    print()
    
    # 獲取數據
    print("[FETCH] Getting daily_workout_summary...")
    summary_data = get_daily_workout_summary()
    print(f"   Found {len(summary_data)} records")
    
    print("[FETCH] Getting workout_plans...")
    workout_plans = get_workout_plans()
    print(f"   Found {len(workout_plans)} records")
    print()
    
    # 計算預期統計
    print("[CALC] Calculating expected stats...")
    expected_stats = calculate_expected_stats(workout_plans)
    print(f"   Calculated {len(expected_stats)} date entries")
    print()
    
    # 比較
    print("[COMPARE] Comparing actual vs expected...")
    errors, matches = compare_stats(summary_data, expected_stats)
    print()
    
    # 輸出結果
    if errors:
        print("=" * 60)
        print(f"[ERROR] Found {len(errors)} mismatches")
        print("=" * 60)
        for err in errors:
            print(f"\n[X] {err['type']}")
            print(f"   User: {err['user_id'][:8]}...")
            print(f"   Date: {err['date']}")
            if "actual" in err and "expected" in err:
                print(f"   Actual: {err['actual']}")
                print(f"   Expected: {err['expected']}")
            if "message" in err:
                print(f"   Message: {err['message']}")
    else:
        print("=" * 60)
        print("[OK] All data is correct!")
        print("=" * 60)
    
    print(f"\n[STATS] {matches}/{len(summary_data)} fully matched")
    
    # 輸出詳細的預期數據供參考
    print("\n" + "=" * 60)
    print("[EXPECTED] Expected stats (calculated from workout_plans)")
    print("=" * 60)
    for key, data in sorted(expected_stats.items(), key=lambda x: x[1]["date"], reverse=True)[:10]:
        print(f"\n{data['date']} | User: {data['user_id'][:8]}...")
        print(f"  expected_total_sets: {data['expected_total_sets']}")
        print(f"  expected_total_volume: {data['expected_total_volume']:.2f}")
        print(f"  expected_workout_count: {data['expected_workout_count']}")
        print(f"  expected_completed_count: {data['workout_completed_true_count']}")
        print(f"  expected_partial_count: {data['workout_partial_count']}")


if __name__ == "__main__":
    main()
