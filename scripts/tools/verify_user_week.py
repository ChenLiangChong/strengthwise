#!/usr/bin/env python3
"""
驗證特定用戶本週訓練數據
"""

import os
from datetime import datetime, timedelta
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# 目標用戶
TARGET_USER = "d1798674-0b96-4c47-a7c7-ee20a5372a03"

# 計算本週範圍 (週一到週日)
today = datetime.now()
monday = today - timedelta(days=today.weekday())
sunday = monday + timedelta(days=6)

week_start = monday.strftime("%Y-%m-%d")
week_end = sunday.strftime("%Y-%m-%d")

print("=" * 70)
print(f"[USER] {TARGET_USER[:8]}...")
print(f"[THIS WEEK] {week_start} ~ {week_end}")
print("=" * 70)

# 獲取該用戶本週所有 workout_plans
print("\n[1] workout_plans for this user")
print("-" * 70)

response = supabase.table("workout_plans").select("*").eq("trainee_id", TARGET_USER).gte("scheduled_date", week_start).lte("scheduled_date", week_end + "T23:59:59").order("scheduled_date").execute()

workout_plans = response.data
print(f"Found {len(workout_plans)} workout_plans\n")

total_workout_count = len(workout_plans)
done_count = 0
partial_count = 0
pending_count = 0

for i, wp in enumerate(workout_plans, 1):
    wp_id = wp.get("id", "")[:8]
    name = wp.get("name") or "N/A"
    scheduled = wp.get("scheduled_date", "")[:10] if wp.get("scheduled_date") else "N/A"
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
    
    if completed:
        status = "DONE"
        done_count += 1
    elif completed_sets > 0:
        status = "PARTIAL"
        partial_count += 1
    else:
        status = "PENDING"
        pending_count += 1
    
    print(f"  {i}. [{status:7}] {scheduled} | {name[:35]:35} | sets: {completed_sets}/{total_sets}")

print("\n" + "-" * 70)
print(f"Summary:")
print(f"  Total workout_plans: {total_workout_count}")
print(f"  DONE:    {done_count}")
print(f"  PARTIAL: {partial_count}")
print(f"  PENDING: {pending_count}")
print(f"  (Has activity = DONE + PARTIAL = {done_count + partial_count})")

# 獲取該用戶本週 daily_workout_summary
print("\n" + "=" * 70)
print("[2] daily_workout_summary for this user")
print("-" * 70)

response2 = supabase.table("daily_workout_summary").select("*").eq("user_id", TARGET_USER).gte("date", week_start).lte("date", week_end).order("date").execute()

summaries = response2.data
print(f"Found {len(summaries)} daily_workout_summary records\n")

total_summary_workout_count = 0
total_summary_completed = 0
total_summary_partial = 0
total_sets = 0
total_volume = 0

total_scheduled = 0

for s in summaries:
    date = s.get("date", "")
    scheduled = s.get("scheduled_workout_count", 0)
    workout_count = s.get("workout_count", 0)
    completed_count = s.get("completed_workout_count", 0)
    partial_count_s = s.get("partial_workout_count", 0)
    sets = s.get("total_sets", 0)
    volume = s.get("total_volume", 0)
    
    total_scheduled += scheduled
    total_summary_workout_count += workout_count
    total_summary_completed += completed_count
    total_summary_partial += partial_count_s
    total_sets += sets
    total_volume += volume
    
    print(f"  {date} | scheduled:{scheduled} active:{workout_count} (done:{completed_count}, partial:{partial_count_s}) | sets: {sets}")

print("\n" + "-" * 70)
print(f"Summary from daily_workout_summary:")
print(f"  Total scheduled (NEW): {total_scheduled}")
print(f"  Total active (workout_count): {total_summary_workout_count}")
print(f"  Total completed: {total_summary_completed}")
print(f"  Total partial: {total_summary_partial}")
print(f"  Training days: {len(summaries)}")
print(f"  Total sets: {total_sets}")
print(f"  Total volume: {total_volume}")

# 比較
print("\n" + "=" * 70)
print("[3] Comparison")
print("-" * 70)
print(f"  workout_plans count:                  {total_workout_count}")
print(f"  daily_summary scheduled_count sum:    {total_scheduled}")
print(f"  workout_plans with activity:          {done_count + partial_count}")
print(f"  daily_summary workout_count sum:      {total_summary_workout_count}")

if total_scheduled == total_workout_count:
    print("\n  [OK] scheduled_workout_count matches total workout_plans!")
else:
    print(f"\n  [MISMATCH] scheduled: Expected {total_workout_count}, got {total_scheduled}")

print("\n" + "=" * 70)
print("[DONE]")
