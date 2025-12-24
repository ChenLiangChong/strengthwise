#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
只生成訓練模板（不生成訓練記錄）
"""

import sys
import os
from datetime import datetime
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
    """生成常用的訓練模板（推拉腿分化）"""
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
    print("生成訓練模板")
    print("=" * 80)
    print()
    print(f"目標用戶: {TARGET_USER_ID}")
    print()
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
    
    print("=" * 80)
    print(f"✓ 完成！共生成 {len(template_refs)} 個訓練模板")
    print("=" * 80)
    print()
    print("現在可以在應用的「訓練」頁面查看並使用這些模板！")
    print()

if __name__ == "__main__":
    main()

