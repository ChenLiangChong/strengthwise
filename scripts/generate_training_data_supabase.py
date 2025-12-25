#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
生成專業的假訓練資料（Supabase 版本）
推拉腿分化（Push-Pull-Legs Split）+ 漸進式超負荷

功能：
- 生成一個月的訓練記錄
- 使用真實的動作 ID（從 Supabase 獲取）
- 符合 WorkoutRecord 模型結構
- 支援漸進式超負荷原則

使用方式:
    python scripts/generate_training_data_supabase.py [user_id]
    
範例:
    python scripts/generate_training_data_supabase.py
    python scripts/generate_training_data_supabase.py 550e8400-e29b-41d4-a716-446655440000
"""

import sys
import os
import uuid
import random
import string
from datetime import datetime, timedelta
from typing import List, Dict, Any
from dotenv import load_dotenv
from supabase import create_client, Client

# 設置 UTF-8 輸出
sys.stdout.reconfigure(encoding='utf-8')

# 載入環境變數
load_dotenv()

# Supabase 配置
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("[ERROR] 請設置 SUPABASE_URL 和 SUPABASE_SERVICE_ROLE_KEY 環境變數")
    sys.exit(1)

# 初始化 Supabase Client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# 目標用戶 ID（可通過命令列參數指定）
if len(sys.argv) > 1:
    TARGET_USER_ID = sys.argv[1]
    print(f"使用命令列指定的 User ID: {TARGET_USER_ID}")
else:
    TARGET_USER_ID = None
    print("未指定 User ID，請輸入用戶 UUID：")
    TARGET_USER_ID = input().strip()
    if not TARGET_USER_ID:
        print("❌ 必須提供 User ID")
        sys.exit(1)

def generate_firestore_id() -> str:
    """生成 Firestore 相容的 ID（20 字符）"""
    chars = string.ascii_letters + string.digits
    return ''.join(random.choice(chars) for _ in range(20))

def get_exercise_by_name(name_keyword: str) -> Dict[str, Any]:
    """根據關鍵字獲取動作"""
    try:
        response = supabase.table('exercises')\
            .select('*')\
            .is_('user_id', 'null')\
            .ilike('name', f'%{name_keyword}%')\
            .limit(1)\
            .execute()
        
        if response.data:
            return response.data[0]
        else:
            print(f"⚠️  找不到包含 '{name_keyword}' 的動作")
            return None
    except Exception as e:
        print(f"❌ 查詢動作失敗: {e}")
        return None

def get_common_exercises() -> Dict[str, Dict]:
    """獲取常見訓練動作"""
    print("\n正在獲取常見訓練動作...")
    
    exercise_keywords = {
        # 胸部
        "bench_press": "臥推",
        "incline_press": "上斜",
        # 背部
        "deadlift": "硬舉",
        "pull_up": "引體",
        "barbell_row": "划船",
        # 腿部
        "squat": "深蹲",
        "leg_press": "腿推",
        # 肩部
        "shoulder_press": "肩推",
        "lateral_raise": "側平舉",
        # 手臂
        "bicep_curl": "二頭",
        "tricep": "三頭",
    }
    
    exercises = {}
    for key, keyword in exercise_keywords.items():
        exercise = get_exercise_by_name(keyword)
        if exercise:
            exercises[key] = {
                "id": exercise['id'],
                "exerciseId": exercise['id'],  # WorkoutExercise 使用 exerciseId
                "name": exercise['name'],
                "actionName": exercise.get('action_name', keyword),
                "equipment": exercise.get('equipment', ''),
                "bodyParts": exercise.get('body_parts', [])
            }
            print(f"  ✅ {key}: {exercise['name'][:30]}...")
        else:
            print(f"  ❌ {key}: 找不到動作")
    
    return exercises

def create_workout_exercise(exercise_data: Dict, sets: int = 4, 
                           base_weight: float = 60.0, 
                           base_reps: int = 10) -> Dict:
    """創建訓練動作（符合 WorkoutExercise 模型）"""
    exercise_id = str(uuid.uuid4())
    
    # 創建每組目標
    set_targets = []
    for i in range(sets):
        set_targets.append({
            "reps": base_reps,
            "weight": base_weight
        })
    
    return {
        "id": exercise_id,  # WorkoutExercise 的臨時 ID（UUID）
        "exerciseId": exercise_data['exerciseId'],  # 關聯到 exercises 表的真實 ID
        "name": exercise_data['name'],
        "actionName": exercise_data.get('actionName', ''),
        "equipment": exercise_data.get('equipment', ''),
        "bodyParts": exercise_data.get('bodyParts', []),
        "sets": sets,
        "reps": base_reps,
        "weight": base_weight,
        "restTime": 90,
        "setTargets": set_targets,
        "notes": ""
    }

def create_workout_plan(date: datetime, title: str, plan_type: str,
                       exercises: List[Dict], user_id: str) -> Dict:
    """創建訓練計劃（符合 WorkoutRecord 模型）"""
    plan_id = generate_firestore_id()
    
    # 計算統計數據
    total_sets = sum(ex['sets'] for ex in exercises)
    total_exercises = len(exercises)
    total_volume = sum(
        ex['weight'] * ex['reps'] * ex['sets'] 
        for ex in exercises 
        if ex.get('weight') and ex.get('reps')
    )
    
    # 計算訓練時長（約5分鐘/組）
    training_time = total_sets * 5
    
    return {
        "id": plan_id,
        "user_id": user_id,
        "trainee_id": user_id,
        "creator_id": user_id,
        "title": title,
        "description": f"{plan_type} - 專業訓練計劃",
        "scheduled_date": date.isoformat(),
        "completed": True,
        "completed_date": date.isoformat(),
        "exercises": exercises,
        "plan_type": "personal",
        "training_time": training_time,
        "total_exercises": total_exercises,
        "total_sets": total_sets,
        "total_volume": total_volume,
        "note": ""
    }

def generate_push_day(week: int, exercises_db: Dict) -> List[Dict]:
    """生成推日訓練"""
    base_weight_multiplier = 1.0 + (week * 0.05)  # 每週增加 5%
    
    workout_exercises = []
    
    # 槓鈴臥推
    if 'bench_press' in exercises_db:
        workout_exercises.append(
            create_workout_exercise(
                exercises_db['bench_press'],
                sets=4,
                base_weight=60.0 * base_weight_multiplier,
                base_reps=10
            )
        )
    
    # 上斜啞鈴推舉
    if 'incline_press' in exercises_db:
        workout_exercises.append(
            create_workout_exercise(
                exercises_db['incline_press'],
                sets=3,
                base_weight=25.0 * base_weight_multiplier,
                base_reps=12
            )
        )
    
    # 肩推
    if 'shoulder_press' in exercises_db:
        workout_exercises.append(
            create_workout_exercise(
                exercises_db['shoulder_press'],
                sets=3,
                base_weight=20.0 * base_weight_multiplier,
                base_reps=12
            )
        )
    
    # 三頭肌訓練
    if 'tricep' in exercises_db:
        workout_exercises.append(
            create_workout_exercise(
                exercises_db['tricep'],
                sets=3,
                base_weight=15.0 * base_weight_multiplier,
                base_reps=15
            )
        )
    
    return workout_exercises

def generate_pull_day(week: int, exercises_db: Dict) -> List[Dict]:
    """生成拉日訓練"""
    base_weight_multiplier = 1.0 + (week * 0.05)
    
    workout_exercises = []
    
    # 硬舉
    if 'deadlift' in exercises_db:
        workout_exercises.append(
            create_workout_exercise(
                exercises_db['deadlift'],
                sets=4,
                base_weight=80.0 * base_weight_multiplier,
                base_reps=8
            )
        )
    
    # 引體向上
    if 'pull_up' in exercises_db:
        workout_exercises.append(
            create_workout_exercise(
                exercises_db['pull_up'],
                sets=4,
                base_weight=0.0,  # 體重訓練
                base_reps=10
            )
        )
    
    # 槓鈴划船
    if 'barbell_row' in exercises_db:
        workout_exercises.append(
            create_workout_exercise(
                exercises_db['barbell_row'],
                sets=3,
                base_weight=50.0 * base_weight_multiplier,
                base_reps=12
            )
        )
    
    # 二頭肌彎舉
    if 'bicep_curl' in exercises_db:
        workout_exercises.append(
            create_workout_exercise(
                exercises_db['bicep_curl'],
                sets=3,
                base_weight=15.0 * base_weight_multiplier,
                base_reps=15
            )
        )
    
    return workout_exercises

def generate_leg_day(week: int, exercises_db: Dict) -> List[Dict]:
    """生成腿日訓練"""
    base_weight_multiplier = 1.0 + (week * 0.05)
    
    workout_exercises = []
    
    # 深蹲
    if 'squat' in exercises_db:
        workout_exercises.append(
            create_workout_exercise(
                exercises_db['squat'],
                sets=4,
                base_weight=80.0 * base_weight_multiplier,
                base_reps=10
            )
        )
    
    # 腿推
    if 'leg_press' in exercises_db:
        workout_exercises.append(
            create_workout_exercise(
                exercises_db['leg_press'],
                sets=3,
                base_weight=120.0 * base_weight_multiplier,
                base_reps=12
            )
        )
    
    return workout_exercises

def generate_month_training(user_id: str, exercises_db: Dict):
    """生成一個月的訓練資料"""
    print("\n開始生成訓練資料...")
    print("=" * 60)
    
    # 計算日期範圍（過去一個月）
    end_date = datetime.now()
    start_date = end_date - timedelta(days=30)
    
    # PPL 循環（Push-Pull-Legs）
    ppl_cycle = ['push', 'pull', 'legs']
    current_day = 0
    week = 0
    
    created_count = 0
    current_date = start_date
    
    while current_date <= end_date:
        # 每週訓練 4-5 天，休息 2-3 天
        day_of_week = current_date.weekday()
        
        # 週日休息
        if day_of_week == 6:
            current_date += timedelta(days=1)
            continue
        
        # 隨機休息（30% 機率）
        if random.random() < 0.3:
            current_date += timedelta(days=1)
            continue
        
        # 決定訓練類型
        training_type = ppl_cycle[current_day % 3]
        
        # 生成對應的訓練
        if training_type == 'push':
            title = f"胸肩三頭訓練 - Week {week + 1}"
            exercises = generate_push_day(week, exercises_db)
        elif training_type == 'pull':
            title = f"背二頭訓練 - Week {week + 1}"
            exercises = generate_pull_day(week, exercises_db)
        else:  # legs
            title = f"腿部訓練 - Week {week + 1}"
            exercises = generate_leg_day(week, exercises_db)
        
        if not exercises:
            print(f"  ⚠️  跳過 {current_date.strftime('%Y-%m-%d')}: 無可用動作")
            current_date += timedelta(days=1)
            continue
        
        # 創建訓練計劃
        workout = create_workout_plan(
            current_date,
            title,
            training_type.capitalize(),
            exercises,
            user_id
        )
        
        try:
            # 插入到 Supabase
            supabase.table('workout_plans').insert(workout).execute()
            created_count += 1
            print(f"  ✅ {current_date.strftime('%Y-%m-%d')}: {title}")
        except Exception as e:
            print(f"  ❌ {current_date.strftime('%Y-%m-%d')}: 插入失敗 - {e}")
        
        # 下一天
        current_day += 1
        if current_day % 7 == 0:
            week += 1
        current_date += timedelta(days=1)
    
    print("=" * 60)
    print(f"\n✅ 完成！共創建 {created_count} 筆訓練記錄")

def main():
    """主函數"""
    print("=" * 60)
    print("StrengthWise - 假訓練資料生成工具（Supabase 版本）")
    print("=" * 60)
    print(f"目標用戶: {TARGET_USER_ID}")
    print(f"時間: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # 1. 獲取常見動作
    exercises_db = get_common_exercises()
    
    if not exercises_db:
        print("\n❌ 無法獲取動作資料，程式終止")
        sys.exit(1)
    
    print(f"\n✅ 成功獲取 {len(exercises_db)} 個動作")
    
    # 2. 生成訓練資料
    generate_month_training(TARGET_USER_ID, exercises_db)
    
    print("\n完成！")

if __name__ == "__main__":
    main()

