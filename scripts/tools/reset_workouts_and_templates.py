#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
重置訓練模板和記錄並生成新資料（Supabase 版本）

功能：
1. 刪除指定用戶的所有訓練計劃（workout_plans）
2. 刪除指定用戶的所有訓練模板（workout_templates）
3. 生成一個月的專業訓練記錄（推拉腿分化 + 漸進式超負荷）
4. 生成多個訓練模板

使用方式:
    python scripts/reset_workouts_and_templates.py <user_id> [--auto-confirm]

範例:
    python scripts/reset_workouts_and_templates.py d1798674-0b96-4c47-a7c7-ee20a5372a03
    python scripts/reset_workouts_and_templates.py d1798674-0b96-4c47-a7c7-ee20a5372a03 --auto-confirm
"""

import sys
import os
import uuid
import random
import string
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
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
    with open(ENV_FILE, 'r', encoding='utf-8-sig') as f:
        env_content = f.read()
    temp_env = ENV_FILE + '.tmp'
    with open(temp_env, 'w', encoding='utf-8') as f:
        f.write(env_content)
    load_dotenv(temp_env)
    os.remove(temp_env)
    print(f"✅ 已載入環境變數: {ENV_FILE}")
else:
    print(f"⚠️  找不到 .env 文件: {ENV_FILE}")
    load_dotenv()

# Supabase 配置
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("[ERROR] 請設置 SUPABASE_URL 和 SUPABASE_SERVICE_ROLE_KEY 環境變數")
    sys.exit(1)

# 初始化 Supabase Client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# 解析命令列參數
AUTO_CONFIRM = '--auto-confirm' in sys.argv

if len(sys.argv) > 1 and not sys.argv[1].startswith('--'):
    TARGET_USER_ID = sys.argv[1]
else:
    print("❌ 請提供用戶 UUID")
    print("使用方式: python scripts/reset_workouts_and_templates.py <user_id> [--auto-confirm]")
    sys.exit(1)

# ==================== 工具函數 ====================

def generate_firestore_id() -> str:
    """生成 Firestore 相容的 ID（20 字符）"""
    chars = string.ascii_letters + string.digits
    return ''.join(random.choice(chars) for _ in range(20))

def get_exercise_by_keyword(keyword: str) -> Optional[Dict[str, Any]]:
    """根據關鍵字搜尋動作"""
    try:
        response = supabase.table('exercises')\
            .select('*')\
            .is_('user_id', 'null')\
            .ilike('name', f'%{keyword}%')\
            .limit(1)\
            .execute()
        if response.data:
            return response.data[0]
        return None
    except Exception as e:
        print(f"  ⚠️  搜尋動作 '{keyword}' 失敗: {e}")
        return None

# ==================== 刪除函數 ====================

def delete_workout_data(user_id: str):
    """刪除用戶的訓練計劃和模板"""
    print("\n" + "=" * 60)
    print("步驟 1: 刪除現有數據")
    print("=" * 60)
    
    try:
        # 刪除訓練計劃（包括記錄和未來計劃）
        print(f"正在刪除用戶 {user_id} 的所有訓練計劃...")
        result = supabase.table('workout_plans')\
            .delete()\
            .eq('user_id', user_id)\
            .execute()
        print(f"  ✅ 已刪除訓練計劃（workout_plans）")
        
        # 刪除訓練模板
        print(f"正在刪除用戶 {user_id} 的所有訓練模板...")
        result = supabase.table('workout_templates')\
            .delete()\
            .eq('user_id', user_id)\
            .execute()
        print(f"  ✅ 已刪除訓練模板（workout_templates）")
        
        print("\n✅ 所有訓練數據已清空！")
        
    except Exception as e:
        print(f"\n❌ 刪除失敗: {e}")
        sys.exit(1)

# ==================== 獲取動作 ====================

def get_training_exercises() -> Dict[str, List[Dict[str, Any]]]:
    """獲取訓練所需的動作（推拉腿分化）"""
    print("\n" + "=" * 60)
    print("步驟 2: 獲取訓練動作")
    print("=" * 60)
    
    exercises = {
        'push': [],  # 推日：胸、肩、三頭
        'pull': [],  # 拉日：背、二頭
        'legs': [],  # 腿日：下肢
    }
    
    # 推日動作
    push_keywords = [
        ('臥推', '槓鈴'),
        ('上斜', '啞鈴'),
        ('夾胸', '器械'),
        ('肩推', '啞鈴'),
        ('側平舉', '啞鈴'),
        ('三頭', '繩索'),
    ]
    
    # 拉日動作
    pull_keywords = [
        ('硬舉', '槓鈴'),
        ('引體', ''),
        ('划船', '槓鈴'),
        ('下拉', '器械'),
        ('二頭', '啞鈴'),
    ]
    
    # 腿日動作
    leg_keywords = [
        ('深蹲', '槓鈴'),
        ('腿推', '器械'),
        ('腿彎舉', '器械'),
        ('提踵', ''),
    ]
    
    # 搜尋推日動作
    print("\n[推日動作]")
    for primary, secondary in push_keywords:
        exercise = get_exercise_by_keyword(primary)
        if exercise and (not secondary or secondary in exercise['name']):
            exercises['push'].append(exercise)
            print(f"  ✅ {exercise['name'][:40]}")
        elif exercise:
            exercises['push'].append(exercise)
            print(f"  ✅ {exercise['name'][:40]}")
    
    # 搜尋拉日動作
    print("\n[拉日動作]")
    for primary, secondary in pull_keywords:
        exercise = get_exercise_by_keyword(primary)
        if exercise and (not secondary or secondary in exercise['name']):
            exercises['pull'].append(exercise)
            print(f"  ✅ {exercise['name'][:40]}")
        elif exercise:
            exercises['pull'].append(exercise)
            print(f"  ✅ {exercise['name'][:40]}")
    
    # 搜尋腿日動作
    print("\n[腿日動作]")
    for primary, secondary in leg_keywords:
        exercise = get_exercise_by_keyword(primary)
        if exercise and (not secondary or secondary in exercise['name']):
            exercises['legs'].append(exercise)
            print(f"  ✅ {exercise['name'][:40]}")
        elif exercise:
            exercises['legs'].append(exercise)
            print(f"  ✅ {exercise['name'][:40]}")
    
    total = len(exercises['push']) + len(exercises['pull']) + len(exercises['legs'])
    print(f"\n✅ 成功獲取 {total} 個動作（推: {len(exercises['push'])}, 拉: {len(exercises['pull'])}, 腿: {len(exercises['legs'])}）")
    
    return exercises

# ==================== 生成訓練記錄 ====================

def generate_exercise_record(exercise: Dict, base_weight: float, week: int) -> Dict[str, Any]:
    """生成單個動作記錄（符合 Dart ExerciseRecord 格式）"""
    # 計算漸進式超負荷（每週 +2.5%）
    weight = base_weight * (1 + week * 0.025)
    weight = round(weight * 2) / 2  # 四捨五入到 0.5kg
    
    # 根據動作類型決定組數和次數
    if '臥推' in exercise['name'] or '深蹲' in exercise['name'] or '硬舉' in exercise['name']:
        # 主要複合動作：5組 x 5-8次
        sets_count = 5
        reps = random.randint(5, 8)
    elif '側平舉' in exercise['name'] or '彎舉' in exercise['name']:
        # 孤立動作：3組 x 12-15次
        sets_count = 3
        reps = random.randint(12, 15)
        weight = weight * 0.4  # 孤立動作重量較輕
    else:
        # 一般動作：4組 x 8-12次
        sets_count = 4
        reps = random.randint(8, 12)
        weight = weight * 0.7
    
    # ✅ 生成 sets（符合 SetRecord 格式）
    sets = []
    for i in range(sets_count):
        # 每組可能有小幅度的重量變化
        set_weight = weight + (random.choice([0, 2.5, 5]) if i >= sets_count - 2 else 0)
        sets.append({
            'setNumber': i + 1,
            'reps': reps,
            'weight': round(set_weight, 1),
            'restTime': 90 if sets_count >= 4 else 60,
            'completed': True,
            'note': '',
        })
    
    # ✅ 返回 ExerciseRecord 格式（已完成的訓練記錄）
    return {
        'exerciseId': exercise['id'],  # 關聯到 exercises 表的真實 ID
        'exerciseName': exercise['name'],
        'trainingType': exercise.get('training_type', '阻力訓練'),  # ⚡ 添加訓練類型
        'sets': sets,
        'notes': '',
        'completed': True,
    }

def generate_workout_records(user_id: str, exercises: Dict[str, List[Dict]]):
    """生成一個月的訓練記錄"""
    print("\n" + "=" * 60)
    print("步驟 3: 生成訓練記錄（過去 30 天）")
    print("=" * 60)
    
    today = datetime.now()
    start_date = today - timedelta(days=30)
    
    # 推拉腿循環
    workout_types = ['push', 'pull', 'legs']
    workout_titles = {
        'push': '胸肩三頭訓練',
        'pull': '背二頭訓練',
        'legs': '腿部訓練',
    }
    
    # 基礎重量（kg）
    base_weights = {
        'push': 60.0,
        'pull': 50.0,
        'legs': 80.0,
    }
    
    created_count = 0
    current_date = start_date
    workout_index = 0
    
    while current_date < today:
        # 週日休息 + 隨機休息
        if current_date.weekday() == 6 or (random.random() < 0.2 and current_date.weekday() != 0):
            current_date += timedelta(days=1)
            continue
        
        workout_type = workout_types[workout_index % 3]
        workout_index += 1
        
        if not exercises[workout_type]:
            current_date += timedelta(days=1)
            continue
        
        # 計算當前週數（用於漸進式超負荷）
        week = (current_date - start_date).days // 7
        
        # 生成動作記錄
        exercise_records = []
        for exercise in exercises[workout_type]:
            exercise_record = generate_exercise_record(
                exercise,
                base_weights[workout_type],
                week
            )
            exercise_records.append(exercise_record)
        
        # 創建訓練記錄
        workout_plan = {
            'id': generate_firestore_id(),
            'user_id': user_id,
            'trainee_id': user_id,
            'creator_id': user_id,
            'title': workout_titles[workout_type],
            'scheduled_date': current_date.replace(hour=18, minute=0).isoformat(),
            'completed_date': current_date.replace(hour=19, minute=30).isoformat(),
            'completed': True,
            'exercises': exercise_records,
            'note': f'週數 {week + 1} - 漸進式超負荷',
            'plan_type': 'personal',
            # training_time 欄位在資料庫中類型不明確，暫時不設定
            'total_exercises': len(exercise_records),
            'total_sets': sum(len(e['sets']) for e in exercise_records),  # ✅ sets 現在是陣列
            'total_volume': sum(s['weight'] * s['reps'] for e in exercise_records for s in e['sets']),  # ✅ 使用 sets
            'created_at': current_date.isoformat(),
            'updated_at': current_date.isoformat(),
        }
        
        try:
            supabase.table('workout_plans').insert(workout_plan).execute()
            created_count += 1
            date_str = current_date.strftime('%m/%d')
            print(f"  ✅ {date_str}: {workout_titles[workout_type]} ({len(exercise_records)} 個動作)")
        except Exception as e:
            print(f"  ❌ {current_date.strftime('%m/%d')} 創建失敗: {e}")
        
        current_date += timedelta(days=1)
    
    print(f"\n✅ 完成！共創建 {created_count} 筆訓練記錄")

# ==================== 生成訓練模板 ====================

def generate_workout_templates(user_id: str, exercises: Dict[str, List[Dict]]):
    """生成訓練模板"""
    print("\n" + "=" * 60)
    print("步驟 4: 生成訓練模板")
    print("=" * 60)
    
    # 模板配置
    templates_config = [
        {
            'title': '力量訓練 - 推日',
            'plan_type': '力量訓練',
            'description': '胸部、肩膀和三頭肌的綜合訓練',
            'workout_type': 'push',
        },
        {
            'title': '力量訓練 - 拉日',
            'plan_type': '力量訓練',
            'description': '背部和二頭肌的綜合訓練',
            'workout_type': 'pull',
        },
        {
            'title': '下肢訓練',
            'plan_type': '力量訓練',
            'description': '腿部和核心的全面訓練',
            'workout_type': 'legs',
        },
        {
            'title': '增肌訓練 - 上肢',
            'plan_type': '增肌訓練',
            'description': '高容量的上肢肌肥大訓練',
            'workout_type': 'push',
        },
        {
            'title': '全身功能性訓練',
            'plan_type': '功能性訓練',
            'description': '全身複合動作的功能性訓練',
            'workout_type': 'pull',
        },
    ]
    
    created_count = 0
    
    for config in templates_config:
        workout_type = config['workout_type']
        
        if not exercises[workout_type]:
            continue
        
        # ✅ 生成動作列表（camelCase 格式，符合 Dart WorkoutExercise）
        template_exercises = []
        for exercise in exercises[workout_type]:
            # 根據動作類型設定預設的組數和目標
            if '臥推' in exercise['name'] or '深蹲' in exercise['name'] or '硬舉' in exercise['name']:
                sets_count = 5
                target_reps = 5
                target_weight = 0.0
            elif '側平舉' in exercise['name'] or '彎舉' in exercise['name']:
                sets_count = 3
                target_reps = 12
                target_weight = 0.0
            else:
                sets_count = 4
                target_reps = 10
                target_weight = 0.0
            
            # 生成 setTargets（每組的目標設定）
            set_targets = []
            for i in range(sets_count):
                set_targets.append({
                    'setNumber': i + 1,
                    'targetReps': target_reps,
                    'targetWeight': target_weight,
                    'restTime': 90,
                })
            
            template_exercises.append({
                'id': str(uuid.uuid4()),  # WorkoutExercise 的臨時 ID
                'exerciseId': exercise['id'],  # 關聯到 exercises 表的真實 ID
                'name': exercise['name'],
                'sets': sets_count,  # 組數
                'setTargets': set_targets,  # ✅ 每組的目標設定
                'notes': '',
            })
        
        # 創建模板
        template = {
            'id': generate_firestore_id(),
            'user_id': user_id,
            'title': config['title'],
            'description': config['description'],
            'plan_type': config['plan_type'],
            'exercises': template_exercises,
            # training_time 欄位暫時不設定（模型中是 DateTime?）
            'created_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat(),
        }
        
        try:
            supabase.table('workout_templates').insert(template).execute()
            created_count += 1
            print(f"  ✅ {config['title']} ({len(template_exercises)} 個動作)")
        except Exception as e:
            print(f"  ❌ {config['title']} 創建失敗: {e}")
    
    print(f"\n✅ 完成！共創建 {created_count} 個訓練模板")

# ==================== 主程式 ====================

def main():
    print("=" * 60)
    print("StrengthWise - 訓練數據重置與生成工具")
    print("=" * 60)
    print(f"目標用戶: {TARGET_USER_ID}")
    print(f"執行時間: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    print("⚠️  此操作將：")
    print("  1. 刪除所有訓練計劃（workout_plans）")
    print("  2. 刪除所有訓練模板（workout_templates）")
    print("  3. 生成 30 天的訓練記錄（推拉腿分化）")
    print("  4. 生成 5 個訓練模板")
    print("=" * 60)
    
    if not AUTO_CONFIRM:
        confirm = input("\n確定要繼續嗎？(輸入 yes 確認): ")
        if confirm.lower() != 'yes':
            print("已取消操作")
            sys.exit(0)
    
    # 執行步驟
    delete_workout_data(TARGET_USER_ID)
    exercises = get_training_exercises()
    generate_workout_records(TARGET_USER_ID, exercises)
    generate_workout_templates(TARGET_USER_ID, exercises)
    
    # 完成
    print("\n" + "=" * 60)
    print("🎉 完成！數據已重置並生成")
    print("=" * 60)
    print()
    print("✅ 訓練記錄：過去 30 天的訓練（推拉腿分化 + 漸進式超負荷）")
    print("✅ 訓練模板：5 個不同類型的訓練模板")
    print()
    print("📱 請在 App 中驗證：")
    print("  - 首頁：查看最近的訓練記錄")
    print("  - 訓練模板頁面：查看新生成的模板")
    print("  - 統計頁面：查看訓練數據圖表")
    print("=" * 60)

if __name__ == '__main__':
    main()

