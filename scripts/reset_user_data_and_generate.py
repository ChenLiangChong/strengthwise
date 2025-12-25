#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
重置用戶數據並生成假資料（Supabase 版本）
專業健身教練訓練計劃生成器

功能：
1. 刪除指定用戶的所有訓練數據
2. 生成一個月的訓練記錄（推拉腿分化）
3. 生成一周的訓練模板

使用方式:
    python scripts/reset_user_data_and_generate.py d1798674-0b96-4c47-a7c7-ee20a5372a03
"""

import sys
import os
import uuid
import random
import string
from datetime import datetime, timedelta
from typing import List, Dict, Any, Tuple
from dotenv import load_dotenv
from supabase import create_client, Client

# 設置 UTF-8 輸出
sys.stdout.reconfigure(encoding='utf-8')

# 獲取專案根目錄
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
ENV_FILE = os.path.join(PROJECT_ROOT, '.env')

# 載入環境變數
if os.path.exists(ENV_FILE):
    # 讀取並清理 BOM
    with open(ENV_FILE, 'r', encoding='utf-8-sig') as f:
        env_content = f.read()
    
    # 重新寫入臨時文件（無 BOM）
    temp_env = ENV_FILE + '.tmp'
    with open(temp_env, 'w', encoding='utf-8') as f:
        f.write(env_content)
    
    load_dotenv(temp_env)
    os.remove(temp_env)
    print(f"✅ 已載入環境變數: {ENV_FILE}")
else:
    print(f"⚠️  找不到 .env 文件: {ENV_FILE}")
    load_dotenv()  # 嘗試從當前目錄載入

# Supabase 配置
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("[ERROR] 請設置 SUPABASE_URL 和 SUPABASE_SERVICE_ROLE_KEY 環境變數")
    print(f"SUPABASE_URL 找到: {'是' if SUPABASE_URL else '否'}")
    print(f"SUPABASE_SERVICE_ROLE_KEY 找到: {'是' if SUPABASE_KEY else '否'}")
    sys.exit(1)

# 初始化 Supabase Client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# 目標用戶 ID
AUTO_CONFIRM = '--auto-confirm' in sys.argv

if len(sys.argv) > 1 and not sys.argv[1].startswith('--'):
    TARGET_USER_ID = sys.argv[1]
    print(f"目標用戶 ID: {TARGET_USER_ID}")
else:
    print("❌ 請提供用戶 UUID")
    print("使用方式: python scripts/reset_user_data_and_generate.py <user_id> [--auto-confirm]")
    sys.exit(1)

def generate_firestore_id() -> str:
    """生成 Firestore 相容的 ID（20 字符）"""
    chars = string.ascii_letters + string.digits
    return ''.join(random.choice(chars) for _ in range(20))

def delete_user_data(user_id: str):
    """刪除用戶的所有訓練數據"""
    print("\n" + "=" * 60)
    print("步驟 1: 刪除現有數據")
    print("=" * 60)
    
    try:
        # 刪除訓練計劃（workout_plans）
        print(f"正在刪除用戶 {user_id} 的訓練計劃...")
        result = supabase.table('workout_plans')\
            .delete()\
            .eq('user_id', user_id)\
            .execute()
        print(f"  ✅ 已刪除訓練計劃")
        
        # 刪除訓練模板（workout_templates）
        print(f"正在刪除用戶 {user_id} 的訓練模板...")
        result = supabase.table('workout_templates')\
            .delete()\
            .eq('user_id', user_id)\
            .execute()
        print(f"  ✅ 已刪除訓練模板")
        
        # 刪除自定義動作（可選，因為這個用戶可能沒有自定義動作）
        print(f"正在刪除用戶 {user_id} 的自定義動作...")
        try:
            result = supabase.table('exercises')\
                .delete()\
                .eq('user_id', user_id)\
                .execute()
            print(f"  ✅ 已刪除自定義動作")
        except Exception as e:
            print(f"  ⚠️  刪除自定義動作失敗（可能沒有）: {e}")
        
        # 刪除預約記錄（如果表存在）
        print(f"正在刪除用戶 {user_id} 的預約記錄...")
        try:
            result = supabase.table('appointments')\
                .delete()\
                .or_(f'coach_id.eq.{user_id},trainee_id.eq.{user_id}')\
                .execute()
            print(f"  ✅ 已刪除預約記錄")
        except Exception as e:
            if 'PGRST205' in str(e) or 'appointments' in str(e).lower():
                print(f"  ⚠️  appointments 表不存在，跳過")
            else:
                raise
        
        print("\n✅ 所有數據已清空！")
        
    except Exception as e:
        print(f"\n❌ 刪除數據時發生錯誤: {e}")
        sys.exit(1)

def get_exercises_from_db() -> Dict[str, Dict]:
    """從資料庫獲取真實動作"""
    print("\n" + "=" * 60)
    print("步驟 2: 獲取真實動作")
    print("=" * 60)
    
    # 定義需要的動作（使用更精確的關鍵字）
    exercise_queries = {
        # 胸部（推）
        "bench_press": "臥推",
        "incline_press": "上斜",
        "chest_fly": "飛鳥",
        
        # 背部（拉）
        "deadlift": "硬舉",
        "pull_up": "引體",
        "barbell_row": "划船",
        "lat_pulldown": "下拉",
        
        # 腿部
        "squat": "深蹲",
        "leg_press": "腿推",
        "leg_curl": "腿彎舉",
        "leg_extension": "腿伸展",
        
        # 肩部
        "shoulder_press": "肩推",
        "lateral_raise": "側平舉",
        "front_raise": "前平舉",
        "rear_delt_fly": "後三角",
        
        # 手臂
        "bicep_curl": "二頭彎舉",
        "tricep_extension": "三頭",
        "hammer_curl": "錘式",
    }
    
    exercises = {}
    
    for key, keyword in exercise_queries.items():
        try:
            response = supabase.table('exercises')\
                .select('*')\
                .is_('user_id', 'null')\
                .ilike('name', f'%{keyword}%')\
                .limit(1)\
                .execute()
            
            if response.data:
                ex = response.data[0]
                exercises[key] = {
                    "id": ex['id'],
                    "exerciseId": ex['id'],
                    "name": ex['name'],
                    "actionName": ex.get('action_name', keyword),
                    "equipment": ex.get('equipment', ''),
                    "bodyParts": ex.get('body_parts', []) if ex.get('body_parts') else []
                }
                print(f"  ✅ {key}: {ex['name'][:60]}")
            else:
                print(f"  ⚠️  {key}: 找不到包含 '{keyword}' 的動作")
        except Exception as e:
            print(f"  ❌ {key}: 查詢失敗 - {e}")
    
    print(f"\n✅ 成功獲取 {len(exercises)} 個動作")
    return exercises

def create_sets(num_sets: int, base_weight: float, base_reps: int, completed: bool = True) -> List[Dict]:
    """創建組數記錄（符合 SetRecord 模型）"""
    sets = []
    for i in range(num_sets):
        # 模擬漸進式減重（金字塔訓練）
        weight_factor = 1.0 if i < 2 else 0.9
        reps_factor = 1.0 if i < 2 else 1.1
        
        sets.append({
            "setNumber": i + 1,                          # 組數編號
            "reps": int(base_reps * reps_factor),       # 重複次數
            "weight": round(base_weight * weight_factor, 1),  # 重量(kg)
            "restTime": 90,                              # 休息時間(秒)
            "completed": completed,                      # 是否已完成（取決於訓練計劃狀態）
            "note": ""                                   # 備註
        })
    return sets

def create_workout_exercise(exercise_data: Dict, num_sets: int, 
                           base_weight: float, base_reps: int, completed: bool = True) -> Dict:
    """創建訓練動作（符合 ExerciseRecord 模型）"""
    return {
        "exerciseId": exercise_data['exerciseId'],       # 關聯的運動ID
        "exerciseName": exercise_data['name'],           # 運動名稱
        "actionName": exercise_data.get('actionName', ''), # 動作別名
        "equipment": exercise_data.get('equipment', ''), # 器材
        "bodyParts": exercise_data.get('bodyParts', []), # 鍛鍊部位
        "sets": create_sets(num_sets, base_weight, base_reps, completed),  # 組數記錄
        "notes": "",                                     # 備註
        "completed": completed                           # 是否已完成
    }

def generate_push_workout(week: int, exercises: Dict) -> Tuple[str, List[Dict]]:
    """生成推日訓練（胸、肩、三頭）"""
    multiplier = 1.0 + (week * 0.025)  # 每週進步 2.5%
    
    workout = []
    
    # 槓鈴臥推（主要動作）
    if 'bench_press' in exercises:
        workout.append(create_workout_exercise(
            exercises['bench_press'], 5, 60.0 * multiplier, 8
        ))
    
    # 上斜啞鈴推舉
    if 'incline_press' in exercises:
        workout.append(create_workout_exercise(
            exercises['incline_press'], 4, 22.0 * multiplier, 10
        ))
    
    # 胸部飛鳥
    if 'chest_fly' in exercises:
        workout.append(create_workout_exercise(
            exercises['chest_fly'], 3, 15.0 * multiplier, 12
        ))
    
    # 肩推
    if 'shoulder_press' in exercises:
        workout.append(create_workout_exercise(
            exercises['shoulder_press'], 4, 18.0 * multiplier, 10
        ))
    
    # 側平舉
    if 'lateral_raise' in exercises:
        workout.append(create_workout_exercise(
            exercises['lateral_raise'], 3, 8.0 * multiplier, 12
        ))
    
    # 三頭肌伸展
    if 'tricep_extension' in exercises:
        workout.append(create_workout_exercise(
            exercises['tricep_extension'], 3, 12.0 * multiplier, 12
        ))
    
    return "胸肩三頭訓練", workout

def generate_pull_workout(week: int, exercises: Dict) -> Tuple[str, List[Dict]]:
    """生成拉日訓練（背、二頭）"""
    multiplier = 1.0 + (week * 0.025)
    
    workout = []
    
    # 硬舉（主要動作）
    if 'deadlift' in exercises:
        workout.append(create_workout_exercise(
            exercises['deadlift'], 5, 80.0 * multiplier, 6
        ))
    
    # 引體向上
    if 'pull_up' in exercises:
        workout.append(create_workout_exercise(
            exercises['pull_up'], 4, 0.0, 8  # 體重訓練
        ))
    
    # 槓鈴划船
    if 'barbell_row' in exercises:
        workout.append(create_workout_exercise(
            exercises['barbell_row'], 4, 50.0 * multiplier, 10
        ))
    
    # 滑輪下拉
    if 'lat_pulldown' in exercises:
        workout.append(create_workout_exercise(
            exercises['lat_pulldown'], 3, 45.0 * multiplier, 12
        ))
    
    # 二頭彎舉
    if 'bicep_curl' in exercises:
        workout.append(create_workout_exercise(
            exercises['bicep_curl'], 3, 12.0 * multiplier, 12
        ))
    
    title = f"背二頭訓練 - 第{week + 1}週"
    return title, workout

def generate_leg_workout(week: int, exercises: Dict) -> Tuple[str, List[Dict]]:
    """生成腿部訓練"""
    multiplier = 1.0 + (week * 0.025)  # 每週進步 2.5%
    
    workout = []
    
    # 深蹲（主要動作）
    if 'squat' in exercises:
        workout.append(create_workout_exercise(
            exercises['squat'], 5, 80.0 * multiplier, 8
        ))
    
    # 腿推
    if 'leg_press' in exercises:
        workout.append(create_workout_exercise(
            exercises['leg_press'], 4, 120.0 * multiplier, 10
        ))
    
    # 腿彎舉
    if 'leg_curl' in exercises:
        workout.append(create_workout_exercise(
            exercises['leg_curl'], 3, 35.0 * multiplier, 12
        ))
    
    # 腿伸展
    if 'leg_extension' in exercises:
        workout.append(create_workout_exercise(
            exercises['leg_extension'], 3, 40.0 * multiplier, 12
        ))
    
    title = f"腿部訓練 - 第{week + 1}週"
    return title, workout

def generate_shoulder_workout(week: int, exercises: Dict) -> Tuple[str, List[Dict]]:
    """生成肩部訓練"""
    multiplier = 1.0 + (week * 0.025)  # 每週進步 2.5%
    
    workout = []
    
    # 肩推（主要動作）
    if 'shoulder_press' in exercises:
        workout.append(create_workout_exercise(
            exercises['shoulder_press'], 4, 18.0 * multiplier, 10
        ))
    
    # 前平舉
    if 'front_raise' in exercises:
        workout.append(create_workout_exercise(
            exercises['front_raise'], 3, 8.0 * multiplier, 12
        ))
    
    # 側平舉
    if 'lateral_raise' in exercises:
        workout.append(create_workout_exercise(
            exercises['lateral_raise'], 3, 8.0 * multiplier, 12
        ))
    
    # 如果找不到肩部動作，使用肩推替代
    if not workout and 'shoulder_press' in exercises:
        workout.append(create_workout_exercise(
            exercises['shoulder_press'], 4, 18.0 * multiplier, 10
        ))
    
    title = f"肩部訓練 - 第{week + 1}週"
    return title, workout

def generate_arm_workout(week: int, exercises: Dict) -> Tuple[str, List[Dict]]:
    """生成手臂訓練（二頭+三頭）"""
    multiplier = 1.0 + (week * 0.025)  # 每週進步 2.5%
    
    workout = []
    
    # 二頭彎舉
    if 'bicep_curl' in exercises:
        workout.append(create_workout_exercise(
            exercises['bicep_curl'], 4, 12.0 * multiplier, 12
        ))
    
    # 三頭肌伸展
    if 'tricep_extension' in exercises:
        workout.append(create_workout_exercise(
            exercises['tricep_extension'], 4, 12.0 * multiplier, 12
        ))
    
    title = f"手臂訓練 - 第{week + 1}週"
    return title, workout
    """生成腿日訓練"""
    multiplier = 1.0 + (week * 0.025)
    
    workout = []
    
    # 深蹲（主要動作）
    if 'squat' in exercises:
        workout.append(create_workout_exercise(
            exercises['squat'], 5, 80.0 * multiplier, 8
        ))
    
    # 腿推
    if 'leg_press' in exercises:
        workout.append(create_workout_exercise(
            exercises['leg_press'], 4, 120.0 * multiplier, 10
        ))
    
    # 腿彎舉
    if 'leg_curl' in exercises:
        workout.append(create_workout_exercise(
            exercises['leg_curl'], 3, 35.0 * multiplier, 12
        ))
    
    # 腿伸展
    if 'leg_extension' in exercises:
        workout.append(create_workout_exercise(
            exercises['leg_extension'], 3, 40.0 * multiplier, 12
        ))
    
    return "腿部訓練", workout

def create_workout_record(date: datetime, title: str, exercises: List[Dict], 
                         user_id: str, completed: bool = True) -> Dict:
    """創建訓練記錄（符合 workout_plans 表結構）"""
    record_id = generate_firestore_id()
    
    # 計算統計數據（exercises 現在是 ExerciseRecord 格式）
    total_sets = sum(len(ex['sets']) for ex in exercises)  # 修正：計算 sets 列表長度
    total_exercises = len(exercises)
    
    # 計算總訓練量
    total_volume = 0
    for ex in exercises:
        for set_record in ex['sets']:
            total_volume += set_record['weight'] * set_record['reps']
    
    # training_time 欄位在資料庫中是 TIMESTAMPTZ，不應該傳整數
    # 實際訓練時長可以用 total_sets * 5 分鐘估算，但不存儲在這個欄位
    
    return {
        "id": record_id,
        "user_id": user_id,
        "trainee_id": user_id,
        "creator_id": user_id,
        "title": title,
        "description": f"專業訓練計劃 - {title}",
        "scheduled_date": date.isoformat(),
        "completed": completed,
        "completed_date": date.isoformat() if completed else None,
        "exercises": exercises,
        "plan_type": "personal",
        # "training_time": 已移除，資料庫類型為 TIMESTAMPTZ 不相容
        "total_exercises": total_exercises,
        "total_sets": total_sets,
        "total_volume": round(total_volume, 1),
        "note": ""
    }

def generate_training_records(user_id: str, exercises: Dict):
    """生成一個月的訓練記錄"""
    print("\n" + "=" * 60)
    print("步驟 3: 生成訓練記錄（一個月）")
    print("=" * 60)
    
    end_date = datetime.now()
    start_date = end_date - timedelta(days=30)
    
    # PPL 循環
    ppl_cycle = [
        ('push', generate_push_workout),
        ('pull', generate_pull_workout),
        ('legs', generate_leg_workout),
    ]
    
    current_date = start_date
    cycle_index = 0
    week = 0
    created_count = 0
    
    while current_date <= end_date:
        day_of_week = current_date.weekday()
        
        # 週日休息
        if day_of_week == 6:
            current_date += timedelta(days=1)
            continue
        
        # 隨機休息（25% 機率）
        if random.random() < 0.25:
            current_date += timedelta(days=1)
            continue
        
        # 生成訓練
        _, workout_func = ppl_cycle[cycle_index % 3]
        title, workout_exercises = workout_func(week, exercises)
        
        if not workout_exercises:
            current_date += timedelta(days=1)
            continue
        
        # 創建記錄
        record = create_workout_record(
            current_date, title, workout_exercises, user_id, completed=True
        )
        
        try:
            supabase.table('workout_plans').insert(record).execute()
            created_count += 1
            print(f"  ✅ {current_date.strftime('%Y-%m-%d')}: {title} ({len(workout_exercises)} 個動作)")
        except Exception as e:
            print(f"  ❌ {current_date.strftime('%Y-%m-%d')}: 插入失敗 - {e}")
        
        cycle_index += 1
        if cycle_index % 7 == 0:
            week += 1
        current_date += timedelta(days=1)
    
    print(f"\n✅ 完成！共創建 {created_count} 筆訓練記錄")

def convert_exercise_record_to_workout_exercise(exercise_record: Dict) -> Dict:
    """將 ExerciseRecord 格式轉換為 WorkoutExercise 格式（用於模板）"""
    sets_list = exercise_record['sets']
    num_sets = len(sets_list)
    
    # 取第一組的數據作為默認值
    first_set = sets_list[0] if sets_list else {'reps': 10, 'weight': 50.0}
    
    return {
        "id": generate_firestore_id(),  # 生成臨時 ID
        "exerciseId": exercise_record['exerciseId'],
        "name": exercise_record['exerciseName'],
        "actionName": exercise_record.get('actionName', ''),  # 從原始數據獲取
        "equipment": exercise_record.get('equipment', ''),  # 從原始數據獲取
        "bodyParts": exercise_record.get('bodyParts', []),  # 從原始數據獲取
        "sets": num_sets,  # 整數：組數
        "reps": first_set['reps'],  # 整數：每組次數
        "weight": first_set['weight'],  # 浮點數：重量
        "restTime": first_set.get('restTime', 90),  # 整數：休息時間
        "notes": exercise_record.get('notes', ''),
        "isCompleted": False,
        "setTargets": [
            {"reps": s['reps'], "weight": s['weight']}
            for s in sets_list
        ]
    }

def create_workout_template(title: str, exercises: List[Dict], user_id: str) -> Dict:
    """創建訓練模板（插入到 workout_templates 表）"""
    template_id = generate_firestore_id()
    
    # 轉換 exercises 為 WorkoutExercise 格式
    workout_exercises = [
        convert_exercise_record_to_workout_exercise(ex)
        for ex in exercises
    ]
    
    # 根據標題決定訓練類型（必須與 Flutter 的 _planTypes 一致）
    plan_type_mapping = {
        "胸部訓練模板": "力量訓練",
        "背部訓練模板": "力量訓練",
        "腿部訓練模板": "力量訓練",
        "肩部訓練模板": "力量訓練",
        "手臂訓練模板": "增肌訓練",
    }
    plan_type = plan_type_mapping.get(title, "力量訓練")
    
    return {
        "id": template_id,
        "user_id": user_id,
        "title": title,
        "description": f"可自訂的訓練模板 - {title}",
        "exercises": workout_exercises,  # WorkoutExercise 格式
        "plan_type": plan_type,  # 使用 Flutter 中定義的類型
    }

def generate_training_templates(user_id: str, exercises: Dict):
    """生成基礎訓練模板（workout_templates 表）"""
    print("\n" + "=" * 60)
    print("步驟 4: 生成訓練模板（workout_templates）")
    print("=" * 60)
    
    # 基礎訓練模板：胸、背、腿、肩、手臂
    templates = [
        ('胸部訓練模板', generate_push_workout),
        ('背部訓練模板', generate_pull_workout),
        ('腿部訓練模板', generate_leg_workout),
        ('肩部訓練模板', generate_shoulder_workout),
        ('手臂訓練模板', generate_arm_workout),
    ]
    
    created_count = 0
    
    for title, workout_func in templates:
        _, workout_exercises = workout_func(0, exercises)  # Week 0 = 基礎重量
        
        if not workout_exercises:
            print(f"  ⚠️  {title}: 無可用動作，跳過")
            continue
        
        # 將模板的動作設為未完成（模板應該是空白的）
        workout_exercises = set_exercises_completed_status(workout_exercises, False)
        
        # 創建模板
        template = create_workout_template(title, workout_exercises, user_id)
        
        try:
            supabase.table('workout_templates').insert(template).execute()
            created_count += 1
            print(f"  ✅ {title} ({len(workout_exercises)} 個動作)")
        except Exception as e:
            print(f"  ❌ {title}: 插入失敗 - {e}")
    
    print(f"\n✅ 完成！共創建 {created_count} 個訓練模板")

def set_exercises_completed_status(exercises: List[Dict], completed: bool) -> List[Dict]:
    """設置訓練動作的完成狀態"""
    for ex in exercises:
        ex['completed'] = completed
        if 'sets' in ex:
            for set_record in ex['sets']:
                set_record['completed'] = completed
    return exercises

def generate_future_plans(user_id: str, exercises: Dict):
    """生成未來一周的訓練計劃（workout_plans 表，completed=False）"""
    print("\n" + "=" * 60)
    print("步驟 5: 生成未來訓練計劃（workout_plans）")
    print("=" * 60)
    
    # 設定下週的日期
    today = datetime.now()
    next_monday = today + timedelta(days=(7 - today.weekday()))
    
    # 一週訓練計劃（PPL 分化 + 肩日 + 手臂日）
    plans = [
        (0, '週一 - 胸部訓練', generate_push_workout),
        (1, '週二 - 背部訓練', generate_pull_workout),
        (2, '週三 - 腿部訓練', generate_leg_workout),
        (3, '週四 - 肩部訓練', generate_shoulder_workout),
        (4, '週五 - 手臂訓練', generate_arm_workout),
    ]
    
    created_count = 0
    
    for day_offset, title, workout_func in plans:
        plan_date = next_monday + timedelta(days=day_offset)
        _, workout_exercises = workout_func(0, exercises)  # Week 0 = 基礎重量
        
        if not workout_exercises:
            continue
        
        # 將未來計劃的動作設為未完成
        workout_exercises = set_exercises_completed_status(workout_exercises, False)
        
        # 創建未完成的訓練計劃
        plan = create_workout_record(
            plan_date, title, workout_exercises, user_id, completed=False
        )
        
        try:
            supabase.table('workout_plans').insert(plan).execute()
            created_count += 1
            print(f"  ✅ {plan_date.strftime('%m/%d (%a)')}: {title} ({len(workout_exercises)} 個動作)")
        except Exception as e:
            print(f"  ❌ {plan_date.strftime('%m/%d')}: 插入失敗 - {e}")
    
    print(f"\n✅ 完成！共創建 {created_count} 個未來訓練計劃")

def main():
    """主函數"""
    print("\n" + "=" * 60)
    print("StrengthWise - 用戶數據重置與假資料生成工具")
    print("=" * 60)
    print(f"目標用戶: {TARGET_USER_ID}")
    print(f"執行時間: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("")
    print("⚠️  警告：此操作將刪除該用戶的所有訓練數據！")
    print("")
    
    # 確認
    if not AUTO_CONFIRM:
        confirm = input("確定要繼續嗎？(yes/no): ").strip().lower()
        if confirm not in ['yes', 'y']:
            print("❌ 操作已取消")
            sys.exit(0)
    else:
        print("✅ 自動確認模式已啟用，跳過確認步驟")
        print("")
    
    # 1. 刪除現有數據
    delete_user_data(TARGET_USER_ID)
    
    # 2. 獲取真實動作
    exercises = get_exercises_from_db()
    if len(exercises) < 5:
        print("\n❌ 獲取的動作數量不足，程式終止")
        sys.exit(1)
    
    # 3. 生成訓練記錄（一個月）
    generate_training_records(TARGET_USER_ID, exercises)
    
    # 4. 生成訓練模板（workout_templates）
    generate_training_templates(TARGET_USER_ID, exercises)
    
    # 5. 生成未來訓練計劃（workout_plans, completed=False）
    generate_future_plans(TARGET_USER_ID, exercises)
    
    print("\n" + "=" * 60)
    print("🎉 完成！數據已重置並生成假資料")
    print("=" * 60)
    print("\n訓練數據：")
    print("  - 訓練記錄：過去 30 天的訓練（推拉腿分化，completed=True）")
    print("  - 訓練模板：5 個可自訂模板（胸、背、腿、肩、手臂）")
    print("  - 未來計劃：下週 5 天的訓練計劃（completed=False）")
    print("\n訓練特點：")
    print("  - 漸進式超負荷（每週進步 2.5%）")
    print("  - 專業的組數與次數設定")
    print("  - 真實的動作資料")
    print("")

if __name__ == "__main__":
    main()

