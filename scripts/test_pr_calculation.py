#!/usr/bin/env python3
"""
測試 personal_records 重新計算邏輯
檢查是否有數據但沒有生成 PR
"""

import os
import sys
from supabase import create_client

# 載入環境變數
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://eglknvbtpsdcgjpgjqhh.supabase.co")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVnbGtudmJ0cHNkY2dqcGdqcWhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzM4MTYyOTAsImV4cCI6MjA0OTM5MjI5MH0.SBV5U_8vwBmRWYEa4PqH_eoR_L8cZ30dvUU8vr3cqaY")

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

def main():
    print("=" * 60)
    print("檢查 personal_records 重新計算問題")
    print("=" * 60)
    
    # 1. 檢查是否有訓練計畫
    print("\n[1] 檢查訓練計畫...")
    plans_response = supabase.table("workout_plans").select("id, trainee_id, exercises").limit(5).execute()
    plans = plans_response.data
    print(f"✅ 找到 {len(plans)} 個訓練計畫（樣本）")
    
    if not plans:
        print("❌ 沒有訓練計畫！")
        return
    
    # 2. 檢查動作中是否有完成的組數
    print("\n[2] 檢查動作和組數...")
    for i, plan in enumerate(plans[:2]):  # 只檢查前 2 個
        exercises = plan.get("exercises", [])
        print(f"\n訓練計畫 {i+1} (ID: {plan['id'][:8]}...):")
        print(f"  - 動作數量: {len(exercises)}")
        
        for ex in exercises[:2]:  # 只看前 2 個動作
            ex_id = ex.get("exerciseId", "N/A")
            ex_name = ex.get("exerciseName", "N/A")
            body_part = ex.get("bodyPart", "⚠️ 缺少")
            sets = ex.get("sets", [])
            
            completed_sets = [s for s in sets if s.get("completed") in [True, "true"]]
            
            print(f"  - 動作: {ex_name} (ID: {ex_id})")
            print(f"    body_part: {body_part}")
            print(f"    組數: {len(sets)} 個，完成: {len(completed_sets)} 個")
            
            if completed_sets:
                max_weight = max((s.get("weight", 0) for s in completed_sets), default=0)
                print(f"    最大重量: {max_weight} kg")
    
    # 3. 檢查 personal_records 表
    print("\n[3] 檢查 personal_records 表...")
    pr_response = supabase.table("personal_records").select("*").limit(10).execute()
    prs = pr_response.data
    print(f"✅ personal_records 表中有 {len(prs)} 條記錄（最多顯示 10 條）")
    
    if not prs:
        print("❌ personal_records 表是空的！")
        print("\n可能原因：")
        print("  1. Migration 重新計算時，WHERE 條件過濾掉了所有數據")
        print("  2. bodyPart 欄位缺失導致 GROUP BY 失敗")
        print("  3. completed 欄位格式不正確")
    else:
        for pr in prs[:3]:
            print(f"  - {pr.get('exercise_name')}: {pr.get('max_weight')} kg × {pr.get('max_reps')} reps")
    
    # 4. 檢查是否有重量 > 0 的完成組數
    print("\n[4] 測試 Migration 查詢條件...")
    print("模擬 Migration 的查詢邏輯...")
    
    test_query = """
    SELECT COUNT(*) as total_sets,
           COUNT(DISTINCT wp.trainee_id) as total_users
    FROM workout_plans wp,
    LATERAL jsonb_array_elements(wp.exercises) AS ex,
    LATERAL jsonb_array_elements(ex->'sets') AS s
    WHERE (s->>'completed' = 'true' OR (s->'completed')::boolean = true)
      AND (s->>'weight')::DECIMAL > 0
    """
    
    try:
        result = supabase.rpc("exec_sql", {"sql": test_query}).execute()
        print(f"❌ 無法執行測試查詢（RPC 函數不存在）")
    except Exception as e:
        print(f"⚠️ 跳過測試查詢（需要在 Supabase 手動執行）")
    
    print("\n" + "=" * 60)
    print("建議：在 Supabase SQL Editor 執行以下查詢來檢查：")
    print("=" * 60)
    print("""
-- 檢查是否有符合條件的組數
SELECT COUNT(*) as total_sets,
       COUNT(DISTINCT wp.trainee_id) as total_users,
       COUNT(DISTINCT ex->>'exerciseId') as total_exercises
FROM workout_plans wp,
LATERAL jsonb_array_elements(wp.exercises) AS ex,
LATERAL jsonb_array_elements(ex->'sets') AS s
WHERE (s->>'completed' = 'true' OR (s->'completed')::boolean = true)
  AND (s->>'weight')::DECIMAL > 0;

-- 檢查 bodyPart 是否存在
SELECT 
  COUNT(*) as total_exercises,
  COUNT(CASE WHEN ex->>'bodyPart' IS NULL THEN 1 END) as missing_body_part
FROM workout_plans wp,
LATERAL jsonb_array_elements(wp.exercises) AS ex;
    """)
    print("=" * 60)

if __name__ == "__main__":
    main()

