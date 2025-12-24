#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
生成專業的一個月訓練假資料（作為專業健身教練）
推拉腿分化（Push-Pull-Legs Split）+ 漸進式超負荷
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

# 目標用戶（可通過命令列參數指定）
if len(sys.argv) > 1:
    TARGET_USER_ID = sys.argv[1]
    print(f"使用命令列指定的 UID: {TARGET_USER_ID}")
else:
    TARGET_USER_ID = "UmtFu02WQ4QUoTV3x6AFRbd1ov52"
    print(f"使用默認 UID: {TARGET_USER_ID}")

# 真實的動作 ID（從 Firestore 查詢得到）
# 包含完整的動作資訊，符合 WorkoutExercise 模型
EXERCISES = {
    # 胸部動作
    "bench_press": {
        "id": "3zsvNeYy7QC4NNbfB8Cf",
        "name": "推／胸推／地板臥推／槓鈴，推舉",
        "actionName": "臥推",
        "equipment": "槓鈴",
        "bodyParts": ["胸部", "三頭肌", "肩部"]
    },
    "incline_db_press": {
        "id": "5yNv0j7fdFEEpuLpA1x5", 
        "name": "推／胸推／地板臥推／啞鈴，交替推舉",
        "actionName": "上斜啞鈴推舉",
        "equipment": "啞鈴",
        "bodyParts": ["胸部上側", "三頭肌", "肩部"]
    },
    # 背部動作
    "deadlift": {
        "id": "2DeZfox55TfdzMzO4TX2",
        "name": "下肢／硬舉系列／直膝挺髖／雙腳／啞鈴，前舉",
        "actionName": "硬舉",
        "equipment": "啞鈴",
        "bodyParts": ["背部", "腿部", "臀部"]
    },
    "pull_up": {
        "id": "Eh6KPbv5fzn1kVlnmIVl",
        "name": "TRX/引體向上",
        "actionName": "引體向上",
        "equipment": "TRX/單槓",
        "bodyParts": ["背闊肌", "二頭肌"]
    },
    "barbell_row": {
        "id": "0K1ohnKBkP3CBriDuwpx",
        "name": "拉／划船系列／單足立／啞鈴划船，單臂／同側，寬距",
        "actionName": "槓鈴划船",
        "equipment": "啞鈴",
        "bodyParts": ["背部", "斜方肌"]
    },
    # 腿部動作
    "squat": {
        "id": "0cHIY1SKk1d4OYaQrA1t",
        "name": "下肢／深蹲系列／單腳蹲／啞鈴，前舉，單側蹲",
        "actionName": "深蹲",
        "equipment": "啞鈴",
        "bodyParts": ["股四頭肌", "臀部", "核心"]
    },
    "leg_press": {
        "id": "37HfmVRA1CLMcLN8JrNh",
        "name": "下肢／深蹲系列／跨側蹲／槓鈴，垂放，單側蹲",
        "actionName": "腿推",
        "equipment": "槓鈴",
        "bodyParts": ["股四頭肌", "臀部"]
    },
    # 肩部動作
    "shoulder_press": {
        "id": "6hvpsp4UIyWptRYJYL2l",
        "name": "推／肩推／直立式，彈力繩／單手",
        "actionName": "肩推",
        "equipment": "彈力繩",
        "bodyParts": ["肩部", "三頭肌"]
    },
    "lateral_raise": {
        "id": "6mMd1EMonuwNpujwiqlr",
        "name": "推／肩推／倒立式",
        "actionName": "側平舉",
        "equipment": "啞鈴",
        "bodyParts": ["肩部側面"]
    },
    # 手臂動作
    "bicep_curl": {
        "id": "8WkB8x58YqYWHYorHJvE",
        "name": "拉／二頭彎舉／肩前肘固定，半固定器材／單手",
        "actionName": "二頭彎舉",
        "equipment": "啞鈴",
        "bodyParts": ["二頭肌"]
    },
}

# 專業訓練計劃：推拉腿 4 週循環（每週 3-4 次訓練）
def generate_training_plan():
    """
    生成一個月的訓練計劃
    週期化訓練：第 1-2 週（適應期）、第 3-4 週（進步期）
    """
    
    workouts = []
    
    # 第 1 週（適應期）- Days 0, 2, 4, 6
    workouts.extend([
        {
            "title": "第1週 推日 A - 胸肩適應",
            "day_offset": 29,  # 29天前
            "planType": "力量訓練",
            "exercises": [
                {
                    "ex_id": "bench_press",
                    "sets": [
                        {"weight": 55, "reps": 10},
                        {"weight": 60, "reps": 8},
                        {"weight": 60, "reps": 8},
                    ]
                },
                {
                    "ex_id": "incline_db_press",
                    "sets": [
                        {"weight": 20, "reps": 10},
                        {"weight": 22, "reps": 8},
                        {"weight": 22, "reps": 8},
                    ]
                },
                {
                    "ex_id": "shoulder_press",
                    "sets": [
                        {"weight": 16, "reps": 12},
                        {"weight": 18, "reps": 10},
                        {"weight": 18, "reps": 10},
                    ]
                },
                {
                    "ex_id": "lateral_raise",
                    "sets": [
                        {"weight": 8, "reps": 12},
                        {"weight": 10, "reps": 12},
                        {"weight": 10, "reps": 10},
                    ]
                },
            ]
        },
        {
            "title": "第1週 拉日 A - 背部基礎",
            "day_offset": 27,
            "planType": "力量訓練",
            "exercises": [
                {
                    "ex_id": "deadlift",
                    "sets": [
                        {"weight": 80, "reps": 8},
                        {"weight": 90, "reps": 6},
                        {"weight": 100, "reps": 5},
                    ]
                },
                {
                    "ex_id": "pull_up",
                    "sets": [
                        {"weight": 0, "reps": 8},
                        {"weight": 0, "reps": 7},
                        {"weight": 0, "reps": 6},
                        {"weight": 0, "reps": 5},
                    ]
                },
                {
                    "ex_id": "barbell_row",
                    "sets": [
                        {"weight": 50, "reps": 10},
                        {"weight": 55, "reps": 8},
                        {"weight": 55, "reps": 8},
                    ]
                },
                {
                    "ex_id": "bicep_curl",
                    "sets": [
                        {"weight": 20, "reps": 12},
                        {"weight": 22, "reps": 10},
                        {"weight": 22, "reps": 10},
                    ]
                },
            ]
        },
        {
            "title": "第1週 腿日 A - 下肢基礎",
            "day_offset": 25,
            "planType": "力量訓練",
            "exercises": [
                {
                    "ex_id": "squat",
                    "sets": [
                        {"weight": 70, "reps": 10},
                        {"weight": 75, "reps": 8},
                        {"weight": 80, "reps": 6},
                        {"weight": 75, "reps": 8},
                    ]
                },
                {
                    "ex_id": "leg_press",
                    "sets": [
                        {"weight": 100, "reps": 12},
                        {"weight": 110, "reps": 12},
                        {"weight": 120, "reps": 10},
                    ]
                },
            ]
        },
        {
            "title": "第1週 推日 B - 肩部重點",
            "day_offset": 23,
            "planType": "力量訓練",
            "exercises": [
                {
                    "ex_id": "shoulder_press",
                    "sets": [
                        {"weight": 18, "reps": 10},
                        {"weight": 20, "reps": 8},
                        {"weight": 20, "reps": 8},
                    ]
                },
                {
                    "ex_id": "bench_press",
                    "sets": [
                        {"weight": 60, "reps": 8},
                        {"weight": 62, "reps": 6},
                        {"weight": 62, "reps": 6},
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
    ])
    
    # 第 2 週（適應期延續）- Days 15, 17, 19, 21
    workouts.extend([
        {
            "title": "第2週 推日 A - 胸部進步",
            "day_offset": 22,
            "planType": "力量訓練",
            "exercises": [
                {
                    "ex_id": "bench_press",
                    "sets": [
                        {"weight": 60, "reps": 8},
                        {"weight": 65, "reps": 6},
                        {"weight": 65, "reps": 6},
                        {"weight": 60, "reps": 8},
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
            ]
        },
        {
            "title": "第2週 拉日 A - 背部厚度",
            "day_offset": 20,
            "planType": "力量訓練",
            "exercises": [
                {
                    "ex_id": "deadlift",
                    "sets": [
                        {"weight": 90, "reps": 6},
                        {"weight": 100, "reps": 5},
                        {"weight": 110, "reps": 3},
                        {"weight": 100, "reps": 5},
                    ]
                },
                {
                    "ex_id": "pull_up",
                    "sets": [
                        {"weight": 0, "reps": 9},
                        {"weight": 0, "reps": 8},
                        {"weight": 0, "reps": 7},
                        {"weight": 0, "reps": 6},
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
                        {"weight": 22, "reps": 10},
                        {"weight": 25, "reps": 8},
                        {"weight": 25, "reps": 8},
                    ]
                },
            ]
        },
        {
            "title": "第2週 腿日 A - 力量提升",
            "day_offset": 18,
            "planType": "力量訓練",
            "exercises": [
                {
                    "ex_id": "squat",
                    "sets": [
                        {"weight": 75, "reps": 8},
                        {"weight": 80, "reps": 6},
                        {"weight": 85, "reps": 5},
                        {"weight": 80, "reps": 6},
                    ]
                },
                {
                    "ex_id": "leg_press",
                    "sets": [
                        {"weight": 110, "reps": 12},
                        {"weight": 120, "reps": 10},
                        {"weight": 130, "reps": 10},
                    ]
                },
            ]
        },
        {
            "title": "第2週 推日 B - 肌肥大",
            "day_offset": 16,
            "planType": "肌肥大訓練",
            "exercises": [
                {
                    "ex_id": "incline_db_press",
                    "sets": [
                        {"weight": 24, "reps": 10},
                        {"weight": 26, "reps": 8},
                        {"weight": 26, "reps": 8},
                        {"weight": 24, "reps": 10},
                    ]
                },
                {
                    "ex_id": "shoulder_press",
                    "sets": [
                        {"weight": 20, "reps": 10},
                        {"weight": 22, "reps": 8},
                        {"weight": 22, "reps": 8},
                    ]
                },
                {
                    "ex_id": "lateral_raise",
                    "sets": [
                        {"weight": 12, "reps": 12},
                        {"weight": 14, "reps": 10},
                        {"weight": 14, "reps": 10},
                    ]
                },
            ]
        },
    ])
    
    # 第 3 週（進步期）- Days 8, 10, 12, 14
    workouts.extend([
        {
            "title": "第3週 推日 A - 力量突破",
            "day_offset": 15,
            "planType": "力量訓練",
            "exercises": [
                {
                    "ex_id": "bench_press",
                    "sets": [
                        {"weight": 65, "reps": 6},
                        {"weight": 70, "reps": 5},
                        {"weight": 72, "reps": 4},
                        {"weight": 65, "reps": 6},
                    ]
                },
                {
                    "ex_id": "incline_db_press",
                    "sets": [
                        {"weight": 24, "reps": 10},
                        {"weight": 26, "reps": 8},
                        {"weight": 26, "reps": 8},
                        {"weight": 24, "reps": 8},
                    ]
                },
                {
                    "ex_id": "shoulder_press",
                    "sets": [
                        {"weight": 20, "reps": 10},
                        {"weight": 22, "reps": 8},
                        {"weight": 24, "reps": 6},
                    ]
                },
                {
                    "ex_id": "lateral_raise",
                    "sets": [
                        {"weight": 12, "reps": 12},
                        {"weight": 14, "reps": 10},
                        {"weight": 14, "reps": 10},
                    ]
                },
            ]
        },
        {
            "title": "第3週 拉日 A - 硬舉進步",
            "day_offset": 13,
            "planType": "力量訓練",
            "exercises": [
                {
                    "ex_id": "deadlift",
                    "sets": [
                        {"weight": 100, "reps": 5},
                        {"weight": 110, "reps": 3},
                        {"weight": 120, "reps": 2},
                        {"weight": 110, "reps": 3},
                    ]
                },
                {
                    "ex_id": "pull_up",
                    "sets": [
                        {"weight": 0, "reps": 10},
                        {"weight": 0, "reps": 9},
                        {"weight": 0, "reps": 8},
                        {"weight": 0, "reps": 7},
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
                        {"weight": 28, "reps": 8},
                        {"weight": 28, "reps": 8},
                    ]
                },
            ]
        },
        {
            "title": "第3週 腿日 A - 深蹲突破",
            "day_offset": 11,
            "planType": "力量訓練",
            "exercises": [
                {
                    "ex_id": "squat",
                    "sets": [
                        {"weight": 80, "reps": 6},
                        {"weight": 85, "reps": 5},
                        {"weight": 90, "reps": 4},
                        {"weight": 85, "reps": 5},
                    ]
                },
                {
                    "ex_id": "leg_press",
                    "sets": [
                        {"weight": 120, "reps": 12},
                        {"weight": 130, "reps": 10},
                        {"weight": 140, "reps": 8},
                    ]
                },
            ]
        },
        {
            "title": "第3週 推日 B - 上胸專注",
            "day_offset": 9,
            "planType": "肌肥大訓練",
            "exercises": [
                {
                    "ex_id": "incline_db_press",
                    "sets": [
                        {"weight": 26, "reps": 10},
                        {"weight": 28, "reps": 8},
                        {"weight": 28, "reps": 8},
                        {"weight": 26, "reps": 8},
                    ]
                },
                {
                    "ex_id": "bench_press",
                    "sets": [
                        {"weight": 65, "reps": 8},
                        {"weight": 67, "reps": 6},
                        {"weight": 67, "reps": 6},
                    ]
                },
                {
                    "ex_id": "shoulder_press",
                    "sets": [
                        {"weight": 22, "reps": 10},
                        {"weight": 24, "reps": 8},
                        {"weight": 24, "reps": 8},
                    ]
                },
            ]
        },
    ])
    
    # 第 4 週（進步期延續）- Days 1, 3, 5, 7
    workouts.extend([
        {
            "title": "第4週 推日 A - 個人記錄挑戰",
            "day_offset": 8,
            "planType": "力量訓練",
            "exercises": [
                {
                    "ex_id": "bench_press",
                    "sets": [
                        {"weight": 65, "reps": 8},
                        {"weight": 70, "reps": 6},
                        {"weight": 75, "reps": 4},  # PR!
                        {"weight": 70, "reps": 5},
                    ]
                },
                {
                    "ex_id": "incline_db_press",
                    "sets": [
                        {"weight": 26, "reps": 10},
                        {"weight": 28, "reps": 8},
                        {"weight": 28, "reps": 8},
                    ]
                },
                {
                    "ex_id": "shoulder_press",
                    "sets": [
                        {"weight": 22, "reps": 10},
                        {"weight": 24, "reps": 8},
                        {"weight": 26, "reps": 6},
                    ]
                },
                {
                    "ex_id": "lateral_raise",
                    "sets": [
                        {"weight": 14, "reps": 12},
                        {"weight": 16, "reps": 10},
                        {"weight": 16, "reps": 10},
                    ]
                },
            ]
        },
        {
            "title": "第4週 拉日 A - 背部高峰",
            "day_offset": 6,
            "planType": "力量訓練",
            "exercises": [
                {
                    "ex_id": "deadlift",
                    "sets": [
                        {"weight": 105, "reps": 5},
                        {"weight": 115, "reps": 3},
                        {"weight": 125, "reps": 2},  # PR!
                        {"weight": 110, "reps": 4},
                    ]
                },
                {
                    "ex_id": "pull_up",
                    "sets": [
                        {"weight": 0, "reps": 11},  # PR!
                        {"weight": 0, "reps": 10},
                        {"weight": 0, "reps": 9},
                        {"weight": 0, "reps": 8},
                    ]
                },
                {
                    "ex_id": "barbell_row",
                    "sets": [
                        {"weight": 60, "reps": 10},
                        {"weight": 65, "reps": 8},
                        {"weight": 70, "reps": 6},  # PR!
                    ]
                },
                {
                    "ex_id": "bicep_curl",
                    "sets": [
                        {"weight": 25, "reps": 12},
                        {"weight": 28, "reps": 10},
                        {"weight": 30, "reps": 8},  # PR!
                    ]
                },
            ]
        },
        {
            "title": "第4週 腿日 A - 下肢巔峰",
            "day_offset": 4,
            "planType": "力量訓練",
            "exercises": [
                {
                    "ex_id": "squat",
                    "sets": [
                        {"weight": 80, "reps": 8},
                        {"weight": 85, "reps": 6},
                        {"weight": 90, "reps": 5},
                        {"weight": 95, "reps": 3},  # PR!
                    ]
                },
                {
                    "ex_id": "leg_press",
                    "sets": [
                        {"weight": 130, "reps": 12},
                        {"weight": 140, "reps": 10},
                        {"weight": 150, "reps": 8},  # PR!
                    ]
                },
            ]
        },
        {
            "title": "第4週 推日 B - 整合訓練",
            "day_offset": 2,
            "planType": "力量訓練",
            "exercises": [
                {
                    "ex_id": "bench_press",
                    "sets": [
                        {"weight": 70, "reps": 8},
                        {"weight": 72, "reps": 6},
                        {"weight": 72, "reps": 6},
                    ]
                },
                {
                    "ex_id": "shoulder_press",
                    "sets": [
                        {"weight": 24, "reps": 10},
                        {"weight": 26, "reps": 8},
                        {"weight": 26, "reps": 8},
                    ]
                },
                {
                    "ex_id": "incline_db_press",
                    "sets": [
                        {"weight": 28, "reps": 10},
                        {"weight": 30, "reps": 8},  # PR!
                        {"weight": 30, "reps": 8},
                    ]
                },
                {
                    "ex_id": "lateral_raise",
                    "sets": [
                        {"weight": 14, "reps": 12},
                        {"weight": 16, "reps": 10},
                        {"weight": 16, "reps": 10},
                    ]
                },
            ]
        },
    ])
    
    return workouts


def create_workout_record(user_id, workout_data, days_ago):
    """創建訓練記錄（包含所有必要欄位）"""
    
    # 計算日期
    now = datetime.now()
    scheduled_time = now - timedelta(days=days_ago)
    completed_time = scheduled_time + timedelta(hours=1, minutes=30)  # 假設訓練1.5小時
    
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
            "completed": True,  # 整個動作已完成
        })
    
    # 計算總訓練量和組數
    total_volume = sum(
        set_data["weight"] * set_data["reps"]
        for ex in workout_data["exercises"]
        for set_data in ex["sets"]
    )
    
    total_sets = sum(
        len(ex["sets"])
        for ex in workout_data["exercises"]
    )
    
    # 創建 workoutPlan 文檔（包含所有必要欄位）
    workout_plan = {
        # 用戶相關
        "userId": user_id,
        "traineeId": user_id,
        "creatorId": user_id,
        
        # 基本資訊
        "title": workout_data["title"],
        "planType": "self",  # 自主訓練
        "uiPlanType": workout_data.get("planType", "力量訓練"),
        
        # 日期（重要！）
        "scheduledDate": scheduled_time,  # 行事曆顯示需要
        "completedDate": completed_time,  # 完成日期
        "trainingTime": scheduled_time,   # 訓練時間
        
        # 狀態
        "completed": True,
        
        # 訓練內容
        "exercises": exercises,
        
        # 統計
        "totalExercises": len(exercises),
        "totalSets": total_sets,
        "totalVolume": total_volume,
        
        # 備註
        "note": f"訓練量: {total_volume:,} kg",
        
        # 時間戳記
        "createdAt": scheduled_time,
        "updatedAt": completed_time,
    }
    
    return workout_plan


def create_workout_exercise(ex_key, sets, reps, weight, restTime, notes="", index=0):
    """創建符合 WorkoutExercise 模型的動作配置"""
    exercise = EXERCISES[ex_key]
    # 使用時間戳 + index 確保唯一性
    timestamp = int(datetime.now().timestamp() * 1000) + index
    return {
        "id": str(timestamp),
        "exerciseId": exercise["id"],
        "name": exercise["name"],
        "actionName": exercise.get("actionName"),
        "equipment": exercise.get("equipment", ""),
        "bodyParts": exercise.get("bodyParts", []),
        "sets": sets,
        "reps": reps,
        "weight": weight,
        "restTime": restTime,
        "notes": notes,
        "isCompleted": False
    }


def generate_training_templates():
    """
    生成常用的訓練模板（推拉腿分化）
    模板不包含日期和完成狀態，只是訓練計劃的藍圖
    """
    templates = [
        {
            "title": "推日 A - 胸肩三頭",
            "description": "以臥推為主的推日訓練，適合週一或週四",
            "planType": "力量訓練",
            "exercises": [
                create_workout_exercise("bench_press", 4, 8, 60.0, 180, "主力動作，注意槓鈴軌跡", 0),
                create_workout_exercise("incline_db_press", 3, 10, 20.0, 120, "輔助動作，上胸發力", 1),
                create_workout_exercise("shoulder_press", 3, 10, 15.0, 90, "肩部訓練", 2),
                create_workout_exercise("lateral_raise", 3, 12, 10.0, 60, "側平舉，雕刻肩部線條", 3),
            ]
        },
        {
            "title": "拉日 A - 背二頭",
            "description": "以硬舉和划船為主的拉日訓練，適合週二或週五",
            "planType": "力量訓練",
            "exercises": [
                create_workout_exercise("deadlift", 4, 5, 100.0, 240, "主力動作，注意腰背保持挺直", 10),
                create_workout_exercise("pull_up", 3, 8, 0.0, 120, "自重訓練，背部發力", 11),
                create_workout_exercise("barbell_row", 4, 10, 50.0, 120, "輔助動作，背部厚度", 12),
                create_workout_exercise("bicep_curl", 3, 12, 12.0, 60, "手臂訓練", 13),
            ]
        },
        {
            "title": "腿日 A - 深蹲為主",
            "description": "以深蹲為主的腿部訓練，適合週三或週六",
            "planType": "力量訓練",
            "exercises": [
                create_workout_exercise("squat", 5, 5, 80.0, 240, "主力動作，深蹲至大腿平行地面", 20),
                create_workout_exercise("leg_press", 4, 12, 100.0, 120, "輔助動作，腿部力量", 21),
                create_workout_exercise("deadlift", 3, 8, 80.0, 180, "羅馬尼亞硬舉，練後鏈", 22),
            ]
        },
        {
            "title": "快速力量訓練",
            "description": "時間不夠時的快速全身訓練方案",
            "planType": "力量訓練",
            "exercises": [
                create_workout_exercise("bench_press", 3, 8, 60.0, 120, "推的動作", 30),
                create_workout_exercise("pull_up", 3, 8, 0.0, 120, "拉的動作", 31),
                create_workout_exercise("squat", 3, 10, 70.0, 120, "腿部動作", 32),
            ]
        }
    ]
    
    return templates


def create_template_document(user_id, template_data):
    """創建訓練模板文檔"""
    now = datetime.now()
    
    # 設定預設訓練時間（下午 6 點）
    training_time = datetime(now.year, now.month, now.day, 18, 0)
    
    template = {
        "userId": user_id,
        "title": template_data["title"],
        "description": template_data["description"],
        "planType": template_data["planType"],
        "exercises": template_data["exercises"],
        "trainingTime": training_time,
        "createdAt": now,
        "updatedAt": now,
    }
    
    return template


def main():
    print("=" * 80)
    print("生成專業訓練假資料（訓練記錄 + 訓練模板）")
    print("=" * 80)
    print()
    print(f"目標用戶: {TARGET_USER_ID}")
    print()
    
    # ========== 第一部分：生成訓練記錄 ==========
    print("【第一部分】生成訓練記錄")
    print("-" * 80)
    print("訓練計劃概述：")
    print("  - 週期：4 週（一個月）")
    print("  - 訓練頻率：每週 3-4 次")
    print("  - 總訓練次數：16 次")
    print("  - 訓練方式：推拉腿分化（PPL Split）")
    print("  - 漸進式超負荷：每週逐漸增加重量")
    print()
    
    # 生成訓練計劃
    workouts = generate_training_plan()
    
    print(f"共生成 {len(workouts)} 次訓練")
    print()
    print("開始上傳到 Firestore...")
    print()
    
    # 生成並上傳訓練記錄
    workout_refs = []
    for i, workout_data in enumerate(workouts, 1):
        days_ago = workout_data["day_offset"]
        
        print(f"[{i:2d}/{len(workouts)}] {workout_data['title']}")
        print(f"        日期: {days_ago} 天前")
        
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
        print(f"        動作: {len(workout_data['exercises'])} 個 | 組數: {total_sets} | 訓練量: {total_volume:,} kg")
        print()
    
    print("-" * 80)
    print(f"✓ 第一部分完成！共生成 {len(workout_refs)} 個訓練記錄")
    print()
    
    # ========== 第二部分：生成訓練模板 ==========
    print("【第二部分】生成訓練模板")
    print("-" * 80)
    print("模板概述：")
    print("  - 推日 A - 胸肩三頭")
    print("  - 拉日 A - 背二頭")
    print("  - 腿日 A - 深蹲為主")
    print("  - 快速力量訓練")
    print()
    
    templates = generate_training_templates()
    template_refs = []
    
    for i, template_data in enumerate(templates, 1):
        print(f"[{i}/{len(templates)}] {template_data['title']}")
        print(f"        描述: {template_data['description']}")
        
        template_doc = create_template_document(TARGET_USER_ID, template_data)
        
        # 上傳到 Firestore
        doc_ref = db.collection('workoutTemplates').document()
        doc_ref.set(template_doc)
        template_refs.append(doc_ref.id)
        
        print(f"        動作: {len(template_data['exercises'])} 個")
        print()
    
    print("-" * 80)
    print(f"✓ 第二部分完成！共生成 {len(template_refs)} 個訓練模板")
    print()
    
    # ========== 總結 ==========
    print("=" * 80)
    print("✓ 全部完成！")
    print("=" * 80)
    print()
    print(f"訓練記錄：{len(workout_refs)} 個")
    print(f"訓練模板：{len(template_refs)} 個")
    print()
    print("現在可以在應用中查看：")
    print("  - 行事曆：顯示所有訓練日期")
    print("  - 統計頁面：查看力量進步曲線")
    print("  - 力量進步：查看個人記錄（PR）")
    print("  - 訓練頁面：使用訓練模板快速創建計劃")
    print()

if __name__ == "__main__":
    main()

