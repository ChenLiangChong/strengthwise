#!/usr/bin/env python3
"""
驗證本週訓練數據
"""

import os
import json
from datetime import datetime, timedelta
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("[ERROR] Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY")
    exit(1)

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# 計算本週範圍 (週一到週日)
today = datetime.now()
# 找到本週一
monday = today - timedelta(days=today.weekday())
sunday = monday + timedelta(days=6)

week_start = monday.strftime("%Y-%m-%d")
week_end = sunday.strftime("%Y-%m-%d")

print("=" * 70)
print(f"[THIS WEEK] {week_start} ~ {week_end}")
print("=" * 70)

# 獲取本週 workout_plans
print("\n[1] workout_plans (raw data)")
print("-" * 70)

response = supabase.table("workout_plans").select("*").gte("scheduled_date", week_start).lte("scheduled_date", week_end + "T23:59:59").execute()

workout_plans = response.data
print(f"Found {len(workout_plans)} workout_plans this week\n")

for wp in workout_plans:
    wp_id = wp.get("id", "")[:8]
    trainee_id = wp.get("trainee_id", "")[:8]
    name = wp.get("name", "N/A")
    scheduled = wp.get("scheduled_date", "")[:10] if wp.get("scheduled_date") else "N/A"
    completed_date = wp.get("completed_date", "")[:10] if wp.get("completed_date") else "N/A"
    completed = wp.get("completed", False)
    exercises = wp.get("exercises", [])
    
    # 計算 set 統計
    total_sets = 0
    completed_sets = 0
    for ex in exercises:
        for s in ex.get("sets", []):
            total_sets += 1
            if s.get("completed"):
                completed_sets += 1
    
    status = "DONE" if completed else ("PARTIAL" if completed_sets > 0 else "PENDING")
    
    print(f"  [{status:7}] {scheduled} | {name[:30]:30} | sets: {completed_sets}/{total_sets} | user: {trainee_id}...")

# 獲取本週 daily_workout_summary
print("\n" + "=" * 70)
print("[2] daily_workout_summary (aggregated)")
print("-" * 70)

response2 = supabase.table("daily_workout_summary").select("*").gte("date", week_start).lte("date", week_end).order("date").execute()

summaries = response2.data
print(f"Found {len(summaries)} daily_workout_summary records this week\n")

for s in summaries:
    user_id = s.get("user_id", "")[:8]
    date = s.get("date", "")
    workout_count = s.get("workout_count", 0)
    completed_count = s.get("completed_workout_count", 0)
    partial_count = s.get("partial_workout_count", 0)
    total_sets = s.get("total_sets", 0)
    total_volume = s.get("total_volume", 0)
    
    print(f"  {date} | user: {user_id}... | workouts: {workout_count} (done:{completed_count}, partial:{partial_count}) | sets: {total_sets} | vol: {total_volume}")

# 比較
print("\n" + "=" * 70)
print("[3] Comparison")
print("-" * 70)

# 按 user+date 分組 workout_plans
from collections import defaultdict
wp_by_user_date = defaultdict(list)
for wp in workout_plans:
    user_id = wp.get("trainee_id")
    scheduled = wp.get("scheduled_date", "")[:10] if wp.get("scheduled_date") else None
    if user_id and scheduled:
        wp_by_user_date[(user_id, scheduled)].append(wp)

# 按 user+date 分組 summaries
summary_by_user_date = {}
for s in summaries:
    user_id = s.get("user_id")
    date = s.get("date")
    if user_id and date:
        summary_by_user_date[(user_id, date)] = s

all_keys = set(wp_by_user_date.keys()) | set(summary_by_user_date.keys())

for key in sorted(all_keys):
    user_id, date = key
    wps = wp_by_user_date.get(key, [])
    summary = summary_by_user_date.get(key)
    
    # 計算預期
    expected_workout_count = 0
    expected_sets = 0
    expected_volume = 0.0
    expected_completed = 0
    expected_partial = 0
    
    for wp in wps:
        exercises = wp.get("exercises", [])
        has_completed_set = False
        for ex in exercises:
            for s in ex.get("sets", []):
                if s.get("completed"):
                    has_completed_set = True
                    expected_sets += 1
                    expected_volume += float(s.get("weight", 0) or 0) * int(s.get("reps", 0) or 0)
        
        if has_completed_set:
            expected_workout_count += 1
            if wp.get("completed"):
                expected_completed += 1
            else:
                expected_partial += 1
    
    # 比較
    if summary:
        actual_wc = summary.get("workout_count", 0)
        actual_sets = summary.get("total_sets", 0)
        actual_vol = summary.get("total_volume", 0)
        actual_completed = summary.get("completed_workout_count", 0)
        actual_partial = summary.get("partial_workout_count", 0)
        
        issues = []
        if actual_wc != expected_workout_count:
            issues.append(f"workout_count: {actual_wc} vs {expected_workout_count}")
        if actual_sets != expected_sets:
            issues.append(f"total_sets: {actual_sets} vs {expected_sets}")
        if abs(actual_vol - expected_volume) > 0.01:
            issues.append(f"volume: {actual_vol} vs {expected_volume}")
        if actual_completed != expected_completed:
            issues.append(f"completed: {actual_completed} vs {expected_completed}")
        if actual_partial != expected_partial:
            issues.append(f"partial: {actual_partial} vs {expected_partial}")
        
        if issues:
            print(f"\n[MISMATCH] {date} | user: {user_id[:8]}...")
            for issue in issues:
                print(f"           {issue}")
        else:
            print(f"[OK] {date} | user: {user_id[:8]}... | {expected_workout_count} workouts, {expected_sets} sets")
    elif expected_workout_count > 0:
        print(f"\n[MISSING] {date} | user: {user_id[:8]}... | Expected {expected_workout_count} workouts but no summary")
    else:
        print(f"[SKIP] {date} | user: {user_id[:8]}... | No completed sets, no summary needed")

print("\n" + "=" * 70)
print("[DONE]")
