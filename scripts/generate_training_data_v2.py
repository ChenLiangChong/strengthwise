#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
生成專業的一周訓練假資料（使用真實動作 ID）
模擬真實的推拉腿（PPL）訓練計劃
"""

import sys
import os
from datetime import datetime, timedelta
from firebase_admin import credentials, firestore, initialize_app

# 設置 UTF-8 輸出
sys.stdout.reconfigure(encoding='utf-8')

# 初始化 Firebase
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
cred_path = os.path.join(project_root, 'strengthwise-service-account.json')
cred = credentials.Certificate(cred_path)
initialize_app(cred)
db = firestore.client()

# 目標用戶
TARGET_USER_ID = "UmtFu02WQ4QUoTV3x6AFRbd1ov52"

# 真實的動作 ID（從 Firestore 查詢得到）
EXERCISES = {
    # 胸部動作
    "bench_press": {
        "id": "3zsvNeYy7QC4NNbfB8Cf",
        "name": "推／胸推／地板臥推／槓鈴，推舉"
    },
    "incline_db_press": {
        "id": "5yNv0j7fdFEEpuLpA1x5", 
        "name": "推／胸推／地板臥推／啞鈴，交替推舉"
    },
    # 背部動作
    "deadlift": {
        "id": "2DeZfox55TfdzMzO4TX2",
        "name": "下肢／硬舉系列／直膝挺髖／雙腳／啞鈴，前舉"
    },
    "pull_up": {
        "id": "Eh6KPbv5fzn1kVlnmIVl",
        "name": "TRX/引體向上"
    },
    "barbell_row": {
        "id": "0K1ohnKBkP3CBriDuwpx",
        "name": "拉／划船系列／單足立／啞鈴划船，單臂／同側，寬距"
    },
    # 腿部動作
    "squat": {
        "id": "0cHIY1SKk1d4OYaQrA1t",
        "name": "下肢／深蹲系列／單腳蹲／啞鈴，前舉，單側蹲"
    },
    "leg_press": {
        "id": "37HfmVRA1CLMcLN8JrNh",
        "name": "下肢／深蹲系列／跨側蹲／槓鈴，垂放，單側蹲"
    },
    # 肩部動作
    "shoulder_press": {
        "id": "6hvpsp4UIyWptRYJYL2l",
        "name": "推／肩推／直立式，彈力繩／單手"
    },
    "lateral_raise": {
        "id": "6mMd1EMonuwNpujwiqlr",
        "name": "推／肩推／倒立式"
    },
    # 手臂動作
    "bicep_curl": {
        "id": "8WkB8x58YqYWHYorHJvE",
        "name": "拉／二頭彎舉／肩前肘固定，半固定器材／單手"
    },
}

# 訓練計劃：推拉腿 (Push-Pull-Legs) 分化
TRAINING_PLAN = {
    "push_day_1": {
        "title": "推日 A - 胸肩三頭",
        "day_offset": 0,  # 今天
        "exercises": [
            {
                "ex_id": "bench_press",
                "sets": [
                    {"weight": 60, "reps": 8},
                    {"weight": 65, "reps": 6},
                    {"weight": 70, "reps": 5},
                    {"weight": 65, "reps": 6},
                ]
            },
            {
                "ex_id": "incline_db_press",
                "sets": [
                    {"weight": 22, "reps": 10},
                    {"weight": 24, "reps": 8},
                    {"weight": 24, "reps": 8},
                ]
            },
            {
                "ex_id": "shoulder_press",
                "sets": [
                    {"weight": 18, "reps": 10},
                    {"weight": 20, "reps": 8},
                    {"weight": 20, "reps": 8},
                ]
            },
            {
                "ex_id": "lateral_raise",
                "sets": [
                    {"weight": 10, "reps": 12},
                    {"weight": 12, "reps": 10},
                    {"weight": 12, "reps": 10},
                ]
            },
        ]
    },
    "pull_day_1": {
        "title": "拉日 A - 背二頭",
        "day_offset": 1,  # 昨天
        "exercises": [
            {
                "ex_id": "deadlift",
                "sets": [
                    {"weight": 100, "reps": 5},
                    {"weight": 110, "reps": 5},
                    {"weight": 120, "reps": 3},
                    {"weight": 110, "reps": 5},
                ]
            },
            {
                "ex_id": "pull_up",
                "sets": [
                    {"weight": 0, "reps": 10},
                    {"weight": 0, "reps": 8},
                    {"weight": 0, "reps": 7},
                    {"weight": 0, "reps": 6},
                ]
            },
            {
                "ex_id": "barbell_row",
                "sets": [
                    {"weight": 60, "reps": 10},
                    {"weight": 65, "reps": 8},
                    {"weight": 65, "reps": 8},
                ]
            },
            {
                "ex_id": "bicep_curl",
                "sets": [
                    {"weight": 25, "reps": 10},
                    {"weight": 30, "reps": 8},
                    {"weight": 30, "reps": 8},
                ]
            },
        ]
    },
    "leg_day_1": {
        "title": "腿日 A - 腿部全面",
        "day_offset": 2,  # 前天
        "exercises": [
            {
                "ex_id": "squat",
                "sets": [
                    {"weight": 80, "reps": 8},
                    {"weight": 85, "reps": 6},
                    {"weight": 90, "reps": 5},
                    {"weight": 85, "reps": 6},
                ]
            },
            {
                "ex_id": "leg_press",
                "sets": [
                    {"weight": 120, "reps": 12},
                    {"weight": 140, "reps": 10},
                    {"weight": 140, "reps": 10},
                ]
            },
        ]
    },
    "push_day_2": {
        "title": "推日 B - 力量突破",
        "day_offset": 4,  # 4天前
        "exercises": [
            {
                "ex_id": "bench_press",
                "sets": [
                    {"weight": 55, "reps": 8},
                    {"weight": 60, "reps": 8},
                    {"weight": 65, "reps": 6},
                    {"weight": 60, "reps": 7},
                ]
            },
            {
                "ex_id": "shoulder_press",
                "sets": [
                    {"weight": 16, "reps": 12},
                    {"weight": 18, "reps": 10},
                    {"weight": 18, "reps": 9},
                ]
            },
        ]
    },
    "pull_day_2": {
        "title": "拉日 B - 背部厚度",
        "day_offset": 5,  # 5天前
        "exercises": [
            {
                "ex_id": "pull_up",
                "sets": [
                    {"weight": 0, "reps": 9},
                    {"weight": 0, "reps": 8},
                    {"weight": 0, "reps": 7},
                    {"weight": 0, "reps": 5},
                ]
            },
            {
                "ex_id": "barbell_row",
                "sets": [
                    {"weight": 55, "reps": 10},
                    {"weight": 60, "reps": 8},
                    {"weight": 60, "reps": 8},
                ]
            },
            {
                "ex_id": "bicep_curl",
                "sets": [
                    {"weight": 20, "reps": 12},
                    {"weight": 25, "reps": 10},
                    {"weight": 25, "reps": 9},
                ]
            },
        ]
    },
    "leg_day_2": {
        "title": "腿日 B - 前側主導",
        "day_offset": 6,  # 6天前
        "exercises": [
            {
                "ex_id": "squat",
                "sets": [
                    {"weight": 75, "reps": 8},
                    {"weight": 80, "reps": 8},
                    {"weight": 85, "reps": 6},
                    {"weight": 80, "reps": 7},
                ]
            },
            {
                "ex_id": "leg_press",
                "sets": [
                    {"weight": 100, "reps": 12},
                    {"weight": 120, "reps": 10},
                    {"weight": 120, "reps": 10},
                ]
            },
        ]
    },
}

def create_workout_record(user_id, workout_data, days_ago):
    """創建訓練記錄"""
    
    # 計算完成時間
    completed_time = datetime.now() - timedelta(days=days_ago)
    
    # 轉換 exercises 為新格式（SetRecord 數組）
    exercises = []
    for ex_data in workout_data["exercises"]:
        ex_key = ex_data["ex_id"]
        ex_info = EXERCISES[ex_key]
        
        # 轉換 sets 為 SetRecord 格式
        set_records = []
        for i, set_data in enumerate(ex_data["sets"]):
            set_records.append({
                "setNumber": i + 1,
                "weight": set_data["weight"],
                "reps": set_data["reps"],
                "completed": True,
                "timestamp": completed_time.isoformat()
            })
        
        exercises.append({
            "exerciseId": ex_info["id"],
            "exerciseName": ex_info["name"],
            "sets": set_records,
        })
    
    # 計算總訓練量
    total_volume = sum(
        set_data["weight"] * set_data["reps"]
        for ex in workout_data["exercises"]
        for set_data in ex["sets"]
    )
    
    # 創建 workoutPlan 文檔
    workout_plan = {
        "userId": user_id,
        "traineeId": user_id,
        "creatorId": user_id,
        "title": workout_data["title"],
        "completed": True,
        "exercises": exercises,
        "createdAt": completed_time,
        "updatedAt": completed_time,
        "notes": f"訓練量: {total_volume:,} kg",
    }
    
    return workout_plan

def main():
    print("=" * 60)
    print("生成專業訓練假資料 V2（使用真實動作 ID）")
    print("=" * 60)
    print()
    
    print(f"目標用戶: {TARGET_USER_ID}")
    print(f"訓練計劃: {len(TRAINING_PLAN)} 次訓練")
    print()
    
    # 生成並上傳訓練記錄
    workout_refs = []
    for workout_key, workout_data in TRAINING_PLAN.items():
        days_ago = workout_data["day_offset"]
        
        print(f"生成: {workout_data['title']} ({days_ago}天前)")
        workout_plan = create_workout_record(TARGET_USER_ID, workout_data, days_ago)
        
        # 上傳到 Firestore
        doc_ref = db.collection('workoutPlans').document()
        doc_ref.set(workout_plan)
        workout_refs.append(doc_ref.id)
        
        # 顯示統計
        total_sets = sum(len(ex["sets"]) for ex in workout_data["exercises"])
        total_volume = sum(
            set_data["weight"] * set_data["reps"]
            for ex in workout_data["exercises"]
            for set_data in ex["sets"]
        )
        print(f"  - {len(workout_data['exercises'])} 個動作, {total_sets} 組, {total_volume:,} kg")
        print()
    
    print("=" * 60)
    print("✓ 完成！")
    print("=" * 60)
    print()
    print("生成的訓練記錄:")
    for i, ref_id in enumerate(workout_refs, 1):
        print(f"  {i}. {ref_id}")
    print()
    print("現在可以在應用中查看統計數據了！")

if __name__ == "__main__":
    main()

