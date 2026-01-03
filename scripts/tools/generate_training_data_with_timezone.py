#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
生成專業的假訓練資料（Supabase 版本 v2.2）
支援時區轉換和新的 training_time_range 欄位

功能：
- 生成過去一個月的訓練記錄
- 使用真實的動作 ID（從 Supabase 獲取）
- 符合 WorkoutRecord 模型結構
- 支援漸進式超負荷原則
- ✅ 正確處理時區（UTC 儲存，本地時間生成）
- ✅ 支援 training_time_range (TSTZRANGE) 欄位

使用方式:
    python scripts/tools/generate_training_data_with_timezone.py [user_id]
    
範例:
    python scripts/tools/generate_training_data_with_timezone.py d1798674-0b96-4c47-a7c7-ee20a5372a03
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

# 嘗試使用 pytz，如果不存在則使用簡單的 UTC 偏移
try:
    import pytz
    LOCAL_TIMEZONE = pytz.timezone('Asia/Taipei')  # UTC+8
    UTC_TIMEZONE = pytz.utc
    USE_PYTZ = True
except ImportError:
    print("⚠️  未安裝 pytz，使用簡單的 UTC 偏移")
    LOCAL_TIMEZONE = None
    UTC_TIMEZONE = None
    USE_PYTZ = False

# Set UTF-8 output
sys.stdout.reconfigure(encoding='utf-8')

# Get project root and load environment variables
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))
ENV_FILE = os.path.join(PROJECT_ROOT, '.env')

# Load environment variables (handle BOM)
if os.path.exists(ENV_FILE):
    with open(ENV_FILE, 'r', encoding='utf-8-sig') as f:
        env_content = f.read()
    temp_env = ENV_FILE + '.tmp'
    with open(temp_env, 'w', encoding='utf-8') as f:
        f.write(env_content)
    load_dotenv(temp_env)
    os.remove(temp_env)
    print(f"✅ Loaded environment variables: {ENV_FILE}")
else:
    load_dotenv()
    print(f"⚠️  Warning: .env file not found at {ENV_FILE}")

# Supabase 配置
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("[ERROR] 請設置 SUPABASE_URL 和 SUPABASE_SERVICE_ROLE_KEY 環境變數")
    sys.exit(1)

# 初始化 Supabase Client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# UTC 偏移（小時）
UTC_OFFSET_HOURS = 8  # UTC+8 for Asia/Taipei

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

def format_utc_timestamp(dt: datetime) -> str:
    """
    將本地時間轉換為 UTC 並格式化為 ISO 8601 字串
    
    Args:
        dt: 本地時區的 datetime（naive）
    
    Returns:
        UTC ISO 8601 字串（例如 "2025-01-02T10:30:00+00:00"）
    """
    if USE_PYTZ:
        # 使用 pytz
        if dt.tzinfo is None:
            dt = LOCAL_TIMEZONE.localize(dt)
        utc_dt = dt.astimezone(UTC_TIMEZONE)
    else:
        # 簡單偏移計算
        utc_dt = dt - timedelta(hours=UTC_OFFSET_HOURS)
    
    # 格式化為 ISO 8601（確保有 +00:00）
    return utc_dt.strftime('%Y-%m-%dT%H:%M:%S') + '+00:00'

def format_tstzrange(start: datetime, end: datetime) -> str:
    """
    格式化為 PostgreSQL TSTZRANGE 字串
    
    Args:
        start: 開始時間（本地時區）
        end: 結束時間（本地時區）
    
    Returns:
        TSTZRANGE 字串（例如 "[2025-01-02T10:30:00+00:00,2025-01-02T11:30:00+00:00)"）
    """
    start_utc = format_utc_timestamp(start)
    end_utc = format_utc_timestamp(end)
    return f"[{start_utc},{end_utc})"

def get_exercise_by_name(name_keyword: str) -> Dict[str, Any]:
    """根據關鍵字獲取系統動作（不使用自訂動作）"""
    try:
        # 只查詢系統動作（user_id IS NULL）
        response = supabase.table('exercises')\
            .select('id, name, action_name, equipment, body_parts')\
            .is_('user_id', 'null')\
            .ilike('name', f'%{name_keyword}%')\
            .limit(1)\
            .execute()
        
        if response.data:
            return response.data[0]
        
        print(f"⚠️  找不到包含 '{name_keyword}' 的系統動作")
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
        "cable_fly": "夾胸",
        # 背部
        "deadlift": "硬舉",
        "pull_up": "引體",
        "barbell_row": "划船",
        "lat_pulldown": "滑輪下拉",
        # 腿部（擴充）⭐
        "squat": "深蹲",
        "bulgarian_split_squat": "保加利亞分腿蹲",
        "lunge": "弓步",
        "leg_curl": "腿部屈曲",
        "hip_thrust": "提臀",
        # 肩部
        "shoulder_press": "肩推",
        "lateral_raise": "側平舉",
        "front_raise": "前平舉",
        # 手臂
        "bicep_curl": "二頭",
        "tricep": "三頭",
        "hammer_curl": "錘式彎舉",
    }
    
    exercises = {}
    for key, keyword in exercise_keywords.items():
        exercise = get_exercise_by_name(keyword)
        if exercise:
            exercises[key] = {
                "id": exercise['id'],
                "exerciseId": exercise['id'],
                "name": exercise['name'],
                "actionName": exercise.get('action_name', keyword),
                "equipment": exercise.get('equipment', ''),
                "bodyParts": exercise.get('body_parts', [])
            }
            print(f"  ✅ {key}: {exercise['name'][:40]}...")
        else:
            print(f"  ⚠️  {key}: 找不到動作（將跳過）")
    
    if not exercises:
        print("\n❌ 沒有找到任何可用的動作！")
        print("提示：請確認資料庫中有動作資料")
    
    return exercises

def create_workout_exercise(exercise_data: Dict, sets: int = 4, 
                          base_weight: float = 60.0, 
                          base_reps: int = 10) -> Dict:
    """創建訓練動作（符合 ExerciseRecord.toJson() 格式）"""
    
    # 創建每組完成資料
    completed_sets = []
    for i in range(sets):
        completed_sets.append({
            "setNumber": i + 1,
            "reps": base_reps,
            "weight": base_weight,
            "completed": True,  # ⭐ Python 布林值
            "restTime": 90
        })
    
    return {
        "exerciseId": exercise_data['exerciseId'],
        "exerciseName": exercise_data['name'],
        "sets": completed_sets,
        "notes": "",
        "completed": True  # ⭐ 改為 True（訓練已完成）
    }

def create_workout_plan(date: datetime, title: str, plan_type: str,
                       exercises: List[Dict], user_id: str,
                       training_start: datetime, training_end: datetime) -> Dict:
    """
    創建訓練計劃（符合 WorkoutRecord 模型 v2.2）
    
    Args:
        date: 訓練日期（本地時區）
        title: 標題
        plan_type: 訓練類型
        exercises: 動作列表
        user_id: 用戶 ID
        training_start: 訓練開始時間（本地時區）
        training_end: 訓練結束時間（本地時區）
    
    Returns:
        workout_plans 表格資料（已轉換為 UTC）
    """
    plan_id = generate_firestore_id()
    
    # 計算統計數據
    total_sets = sum(len(ex['sets']) for ex in exercises)
    total_exercises = len(exercises)
    total_volume = sum(
        s['weight'] * s['reps']
        for ex in exercises
        for s in ex.get('sets', [])
        if s.get('weight') and s.get('reps')
    )
    
    return {
        "id": plan_id,
        "user_id": user_id,
        "trainee_id": user_id,
        "creator_id": user_id,
        "title": title,
        "description": f"{plan_type} - 專業訓練計劃",
        "scheduled_date": format_utc_timestamp(date),  # ⭐ UTC 儲存
        "completed": True,
        "completed_date": format_utc_timestamp(training_end),  # ⭐ UTC 儲存
        "exercises": exercises,
        "plan_type": "personal",
        "training_time": format_utc_timestamp(training_start),  # ⭐ v2.1 訓練開始時間
        "training_time_range": format_tstzrange(training_start, training_end),  # ⭐ v2.2 訓練時間範圍
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
    
    # 硬舉（腿部也練硬舉）
    if 'deadlift' in exercises_db:
        workout_exercises.append(
            create_workout_exercise(
                exercises_db['deadlift'],
                sets=3,
                base_weight=100.0 * base_weight_multiplier,
                base_reps=8
            )
        )
    
    # 保加利亞分腿蹲
    if 'bulgarian_split_squat' in exercises_db:
        workout_exercises.append(
            create_workout_exercise(
                exercises_db['bulgarian_split_squat'],
                sets=3,
                base_weight=20.0 * base_weight_multiplier,
                base_reps=12
            )
        )
    
    # 弓步蹲
    if 'lunge' in exercises_db:
        workout_exercises.append(
            create_workout_exercise(
                exercises_db['lunge'],
                sets=3,
                base_weight=25.0 * base_weight_multiplier,
                base_reps=12
            )
        )
    
    # 腿彎舉（腿後肌）
    if 'leg_curl' in exercises_db:
        workout_exercises.append(
            create_workout_exercise(
                exercises_db['leg_curl'],
                sets=3,
                base_weight=40.0 * base_weight_multiplier,
                base_reps=15
            )
        )
    
    # 臀推
    if 'hip_thrust' in exercises_db:
        workout_exercises.append(
            create_workout_exercise(
                exercises_db['hip_thrust'],
                sets=3,
                base_weight=60.0 * base_weight_multiplier,
                base_reps=12
            )
        )
    
    return workout_exercises

def generate_training_time(base_date: datetime) -> Tuple[datetime, datetime]:
    """
    生成隨機的訓練時間範圍（本地時區）
    
    Args:
        base_date: 訓練日期（本地時區，時間為 00:00:00）
    
    Returns:
        (start_time, end_time) 本地時區的訓練時間範圍
    """
    # 隨機選擇訓練時段（早上 6-10 點，下午 2-6 點，晚上 7-10 點）
    time_slots = [
        (6, 10),   # 早上
        (14, 18),  # 下午
        (19, 22),  # 晚上
    ]
    
    start_hour, end_hour = random.choice(time_slots)
    
    # 隨機選擇具體小時和分鐘
    hour = random.randint(start_hour, end_hour - 1)
    minute = random.choice([0, 15, 30, 45])
    
    # 訓練時長 1-2 小時
    duration_minutes = random.choice([60, 75, 90, 105, 120])
    
    # 生成開始和結束時間（本地時區）
    start_time = base_date.replace(hour=hour, minute=minute, second=0, microsecond=0)
    end_time = start_time + timedelta(minutes=duration_minutes)
    
    return start_time, end_time

def generate_month_training(user_id: str, exercises_db: Dict):
    """生成過去一個月的訓練資料（考慮時區）"""
    print("\n開始生成訓練資料...")
    print("=" * 60)
    if USE_PYTZ:
        print(f"本地時區: {LOCAL_TIMEZONE}")
    else:
        print(f"本地時區: UTC+{UTC_OFFSET_HOURS}")
    print(f"當前時間: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    
    # 計算日期範圍（過去一個月）
    now_local = datetime.now()
    end_date = now_local.replace(hour=0, minute=0, second=0, microsecond=0)
    start_date = end_date - timedelta(days=30)
    
    print(f"生成範圍: {start_date.strftime('%Y-%m-%d')} ~ {end_date.strftime('%Y-%m-%d')}")
    
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
        
        # 生成訓練時間（本地時區）
        training_start, training_end = generate_training_time(current_date)
        
        # 創建訓練計劃（內部會轉換為 UTC）
        workout = create_workout_plan(
            current_date,
            title,
            training_type.capitalize(),
            exercises,
            user_id,
            training_start,
            training_end
        )
        
        try:
            # DEBUG: 打印第一筆資料
            if created_count == 0:
                import json
                print(f"\n[DEBUG] 第一筆要插入的資料:")
                print(json.dumps(workout, indent=2, ensure_ascii=False, default=str))
            
            # 插入到 Supabase
            supabase.table('workout_plans').insert(workout).execute()
            created_count += 1
            
            # 顯示本地時間和 UTC 時間
            local_time_str = training_start.strftime('%H:%M')
            utc_dt = training_start - timedelta(hours=UTC_OFFSET_HOURS)
            utc_time_str = utc_dt.strftime('%H:%M UTC')
            duration = (training_end - training_start).seconds // 60
            
            print(f"  ✅ {current_date.strftime('%Y-%m-%d')} {local_time_str} ({utc_time_str}): {title} [{duration}分鐘]")
        except Exception as e:
            print(f"  ❌ {current_date.strftime('%Y-%m-%d')}: 插入失敗 - {e}")
            if created_count == 0:
                # 第一筆失敗時打印完整錯誤
                import traceback
                traceback.print_exc()
                break
        
        # 下一天
        current_day += 1
        if current_day % 7 == 0:
            week += 1
        current_date += timedelta(days=1)
    
    print("=" * 60)
    print(f"\n✅ 完成！共創建 {created_count} 筆訓練記錄")
    print(f"📊 所有時間已轉換為 UTC 儲存到資料庫")

def main():
    """主函數"""
    print("=" * 60)
    print("StrengthWise - 假訓練資料生成工具（v2.2 時區支援版）")
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

