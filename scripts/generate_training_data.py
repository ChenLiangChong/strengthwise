#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
生成專業的一周訓練假資料
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

# 訓練計劃：推拉腿 (Push-Pull-Legs) 分化
TRAINING_PLAN = {
    "push_day_1": {
        "title": "推日 A - 胸肩三頭",
        "day_offset": 0,  # 今天
        "exercises": [
            {"id": "bench_press", "name": "槓鈴臥推", "bodyPart": "胸", "specificMuscle": "胸大肌", 
             "equipmentCategory": "自由重量", "trainingType": "力量訓練",
             "sets": [
                 {"weight": 60, "reps": 8},
                 {"weight": 65, "reps": 6},
                 {"weight": 70, "reps": 5},
                 {"weight": 65, "reps": 6},
             ]},
            {"id": "incline_db_press", "name": "上斜啞鈴臥推", "bodyPart": "胸", "specificMuscle": "胸大肌上側",
             "equipmentCategory": "自由重量", "trainingType": "肌肥大訓練",
             "sets": [
                 {"weight": 22, "reps": 10},
                 {"weight": 24, "reps": 8},
                 {"weight": 24, "reps": 8},
             ]},
            {"id": "shoulder_press", "name": "啞鈴肩推", "bodyPart": "肩", "specificMuscle": "三角肌前束",
             "equipmentCategory": "自由重量", "trainingType": "肌肥大訓練",
             "sets": [
                 {"weight": 18, "reps": 10},
                 {"weight": 20, "reps": 8},
                 {"weight": 20, "reps": 8},
             ]},
            {"id": "lateral_raise", "name": "啞鈴側平舉", "bodyPart": "肩", "specificMuscle": "三角肌中束",
             "equipmentCategory": "自由重量", "trainingType": "肌肥大訓練",
             "sets": [
                 {"weight": 10, "reps": 12},
                 {"weight": 12, "reps": 10},
                 {"weight": 12, "reps": 10},
             ]},
            {"id": "tricep_pushdown", "name": "繩索下壓", "bodyPart": "手臂", "specificMuscle": "肱三頭肌",
             "equipmentCategory": "固定器械", "trainingType": "肌肥大訓練",
             "sets": [
                 {"weight": 30, "reps": 12},
                 {"weight": 35, "reps": 10},
                 {"weight": 35, "reps": 10},
             ]},
        ]
    },
    "pull_day_1": {
        "title": "拉日 A - 背二頭",
        "day_offset": 1,  # 昨天
        "exercises": [
            {"id": "deadlift", "name": "硬舉", "bodyPart": "背", "specificMuscle": "豎脊肌",
             "equipmentCategory": "自由重量", "trainingType": "力量訓練",
             "sets": [
                 {"weight": 100, "reps": 5},
                 {"weight": 110, "reps": 5},
                 {"weight": 120, "reps": 3},
                 {"weight": 110, "reps": 5},
             ]},
            {"id": "pull_up", "name": "引體向上", "bodyPart": "背", "specificMuscle": "闊背肌",
             "equipmentCategory": "自重訓練", "trainingType": "肌肥大訓練",
             "sets": [
                 {"weight": 0, "reps": 10},
                 {"weight": 0, "reps": 8},
                 {"weight": 0, "reps": 7},
                 {"weight": 0, "reps": 6},
             ]},
            {"id": "barbell_row", "name": "槓鈴划船", "bodyPart": "背", "specificMuscle": "闊背肌",
             "equipmentCategory": "自由重量", "trainingType": "肌肥大訓練",
             "sets": [
                 {"weight": 60, "reps": 10},
                 {"weight": 65, "reps": 8},
                 {"weight": 65, "reps": 8},
             ]},
            {"id": "face_pull", "name": "繩索面拉", "bodyPart": "肩", "specificMuscle": "三角肌後束",
             "equipmentCategory": "固定器械", "trainingType": "肌肥大訓練",
             "sets": [
                 {"weight": 20, "reps": 15},
                 {"weight": 25, "reps": 12},
                 {"weight": 25, "reps": 12},
             ]},
            {"id": "bicep_curl", "name": "槓鈴彎舉", "bodyPart": "手臂", "specificMuscle": "肱二頭肌",
             "equipmentCategory": "自由重量", "trainingType": "肌肥大訓練",
             "sets": [
                 {"weight": 25, "reps": 10},
                 {"weight": 30, "reps": 8},
                 {"weight": 30, "reps": 8},
             ]},
        ]
    },
    "leg_day_1": {
        "title": "腿日 A - 腿部全面",
        "day_offset": 2,  # 前天
        "exercises": [
            {"id": "squat", "name": "槓鈴深蹲", "bodyPart": "腿", "specificMuscle": "股四頭肌",
             "equipmentCategory": "自由重量", "trainingType": "力量訓練",
             "sets": [
                 {"weight": 80, "reps": 8},
                 {"weight": 85, "reps": 6},
                 {"weight": 90, "reps": 5},
                 {"weight": 85, "reps": 6},
             ]},
            {"id": "leg_press", "name": "腿推", "bodyPart": "腿", "specificMuscle": "股四頭肌",
             "equipmentCategory": "固定器械", "trainingType": "肌肥大訓練",
             "sets": [
                 {"weight": 120, "reps": 12},
                 {"weight": 140, "reps": 10},
                 {"weight": 140, "reps": 10},
             ]},
            {"id": "leg_curl", "name": "腿彎舉", "bodyPart": "腿", "specificMuscle": "股二頭肌",
             "equipmentCategory": "固定器械", "trainingType": "肌肥大訓練",
             "sets": [
                 {"weight": 40, "reps": 12},
                 {"weight": 45, "reps": 10},
                 {"weight": 45, "reps": 10},
             ]},
            {"id": "calf_raise", "name": "小腿提踵", "bodyPart": "腿", "specificMuscle": "腓腸肌",
             "equipmentCategory": "固定器械", "trainingType": "肌肥大訓練",
             "sets": [
                 {"weight": 60, "reps": 15},
                 {"weight": 70, "reps": 12},
                 {"weight": 70, "reps": 12},
                 {"weight": 70, "reps": 10},
             ]},
        ]
    },
    "push_day_2": {
        "title": "推日 B - 力量突破",
        "day_offset": 4,  # 4天前
        "exercises": [
            {"id": "bench_press", "name": "槓鈴臥推", "bodyPart": "胸", "specificMuscle": "胸大肌",
             "equipmentCategory": "自由重量", "trainingType": "力量訓練",
             "sets": [
                 {"weight": 55, "reps": 8},
                 {"weight": 60, "reps": 8},
                 {"weight": 65, "reps": 6},
                 {"weight": 60, "reps": 7},
             ]},
            {"id": "dips", "name": "雙槓撐體", "bodyPart": "胸", "specificMuscle": "胸大肌下側",
             "equipmentCategory": "自重訓練", "trainingType": "肌肥大訓練",
             "sets": [
                 {"weight": 0, "reps": 12},
                 {"weight": 0, "reps": 10},
                 {"weight": 0, "reps": 8},
             ]},
            {"id": "shoulder_press", "name": "啞鈴肩推", "bodyPart": "肩", "specificMuscle": "三角肌前束",
             "equipmentCategory": "自由重量", "trainingType": "肌肥大訓練",
             "sets": [
                 {"weight": 16, "reps": 12},
                 {"weight": 18, "reps": 10},
                 {"weight": 18, "reps": 9},
             ]},
            {"id": "overhead_tricep", "name": "過頭三頭伸展", "bodyPart": "手臂", "specificMuscle": "肱三頭肌",
             "equipmentCategory": "自由重量", "trainingType": "肌肥大訓練",
             "sets": [
                 {"weight": 20, "reps": 12},
                 {"weight": 22, "reps": 10},
                 {"weight": 22, "reps": 10},
             ]},
        ]
    },
    "pull_day_2": {
        "title": "拉日 B - 背部厚度",
        "day_offset": 5,  # 5天前
        "exercises": [
            {"id": "pull_up", "name": "引體向上", "bodyPart": "背", "specificMuscle": "闊背肌",
             "equipmentCategory": "自重訓練", "trainingType": "肌肥大訓練",
             "sets": [
                 {"weight": 0, "reps": 9},
                 {"weight": 0, "reps": 8},
                 {"weight": 0, "reps": 7},
                 {"weight": 0, "reps": 5},  # 力竭
             ]},
            {"id": "db_row", "name": "單臂啞鈴划船", "bodyPart": "背", "specificMuscle": "闊背肌",
             "equipmentCategory": "自由重量", "trainingType": "肌肥大訓練",
             "sets": [
                 {"weight": 30, "reps": 10},
                 {"weight": 32, "reps": 8},
                 {"weight": 32, "reps": 8},
             ]},
            {"id": "lat_pulldown", "name": "滑輪下拉", "bodyPart": "背", "specificMuscle": "闊背肌",
             "equipmentCategory": "固定器械", "trainingType": "肌肥大訓練",
             "sets": [
                 {"weight": 50, "reps": 12},
                 {"weight": 55, "reps": 10},
                 {"weight": 55, "reps": 10},
             ]},
            {"id": "hammer_curl", "name": "錘式彎舉", "bodyPart": "手臂", "specificMuscle": "肱二頭肌",
             "equipmentCategory": "自由重量", "trainingType": "肌肥大訓練",
             "sets": [
                 {"weight": 14, "reps": 12},
                 {"weight": 16, "reps": 10},
                 {"weight": 16, "reps": 9},  # 差一下
             ]},
        ]
    },
    "leg_day_2": {
        "title": "腿日 B - 前側主導",
        "day_offset": 6,  # 6天前
        "exercises": [
            {"id": "squat", "name": "槓鈴深蹲", "bodyPart": "腿", "specificMuscle": "股四頭肌",
             "equipmentCategory": "自由重量", "trainingType": "力量訓練",
             "sets": [
                 {"weight": 75, "reps": 8},
                 {"weight": 80, "reps": 8},
                 {"weight": 85, "reps": 6},
                 {"weight": 80, "reps": 7},
             ]},
            {"id": "front_squat", "name": "前蹲舉", "bodyPart": "腿", "specificMuscle": "股四頭肌",
             "equipmentCategory": "自由重量", "trainingType": "肌肥大訓練",
             "sets": [
                 {"weight": 50, "reps": 10},
                 {"weight": 55, "reps": 8},
                 {"weight": 55, "reps": 8},
             ]},
            {"id": "leg_extension", "name": "腿伸展", "bodyPart": "腿", "specificMuscle": "股四頭肌",
             "equipmentCategory": "固定器械", "trainingType": "肌肥大訓練",
             "sets": [
                 {"weight": 50, "reps": 15},
                 {"weight": 55, "reps": 12},
                 {"weight": 55, "reps": 12},
             ]},
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
            "exerciseId": ex_data["id"],
            "exerciseName": ex_data["name"],
            "sets": set_records,
            # 保留分類信息用於統計
            "bodyPart": ex_data.get("bodyPart", ""),
            "specificMuscle": ex_data.get("specificMuscle", ""),
            "equipmentCategory": ex_data.get("equipmentCategory", ""),
            "trainingType": ex_data.get("trainingType", ""),
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
    print("🏋️ 生成專業訓練假資料")
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

