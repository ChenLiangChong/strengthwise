import pandas as pd
import firebase_admin
from firebase_admin import credentials, firestore
import time
import sys

# 步驟1: 初始化 Firebase Admin SDK
# 您需要從Firebase控制台下載serviceAccountKey.json文件
cred = credentials.Certificate('strengthwise-91f02-firebase-adminsdk-fbsvc-f40743774e.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

# 新增功能：清空集合
def clear_collection(collection_name):
    print(f"正在清空 {collection_name} 集合...")
    docs = db.collection(collection_name).limit(500).stream()
    deleted = 0
    
    for doc in docs:
        doc.reference.delete()
        deleted += 1
    
    if deleted > 0:
        print(f"已刪除 {deleted} 條記錄")
        # 遞迴調用直到集合為空
        clear_collection(collection_name)
    else:
        print(f"{collection_name} 集合已清空")

# 清空所有相關集合
print("⚠️ 警告：此操作將刪除所有現有數據並重新導入。")
confirm = input("確定要繼續嗎？(y/n): ")

if confirm.lower() != 'y':
    print("操作已取消")
    sys.exit(0)

print("開始清空所有集合...")
collections_to_clear = ['exercise', 'bodyParts', 'equipments', 'exerciseTypes', 'jointTypes']
for collection in collections_to_clear:
    clear_collection(collection)

# 步驟2: 讀取CSV文件
print("開始讀取CSV文件...")
df = pd.read_csv('exercises_updated.csv')
print(f"成功讀取CSV文件，共{len(df)}筆記錄")

# 步驟3: 準備批量寫入
batch_size = 400  # Firestore批量寫入限制為500
total_count = 0
current_batch = 0
batch = db.batch()

# 步驟4: 創建集合以追蹤唯一值
unique_body_parts = {}
unique_equipments = {}
unique_types = {}
unique_joint_types = {}
# 建立 ID 映射，用於後續計算真實計數
exercise_ids_by_bodypart = {}
exercise_ids_by_equipment = {}
exercise_ids_by_type = {}
exercise_ids_by_jointtype = {}

print("開始處理資料...")

# 步驟5: 遍歷CSV數據並處理
for index, row in df.iterrows():
    # 資料清洗與轉換
    name = str(row['name']) if pd.notna(row['name']) else ""
    name_en = str(row['nameEn']) if pd.notna(row['nameEn']) else ""
    body_part = str(row['bodyParts']) if pd.notna(row['bodyParts']) else ""
    # 處理 bodyParts 為數組
    body_parts_array = [body_part] if body_part else []
    
    exercise_type = str(row['type']) if pd.notna(row['type']) else ""
    equipment = str(row['equipment']) if pd.notna(row['equipment']) else ""
    
    # 處理單關節/多關節
    joint_type_value = row['jointType'] if pd.notna(row['jointType']) else None
    if joint_type_value == 1:
        joint_type = "單關節"
    elif joint_type_value == 2:
        joint_type = "多關節"
    else:
        joint_type = ""
    
    # 獲取分類層級和動作名稱
    level1 = str(row['level1']) if pd.notna(row['level1']) else ""
    level2 = str(row['level2']) if pd.notna(row['level2']) else ""
    level3 = str(row['level3']) if pd.notna(row['level3']) else ""
    level4 = str(row['level4']) if pd.notna(row['level4']) else ""
    level5 = str(row['level5']) if pd.notna(row['level5']) else ""
    action_name = str(row['actionName']) if pd.notna(row['actionName']) else ""
    
    # 處理描述和URL
    description = str(row['description']) if pd.notna(row['description']) else ""
    image_url = str(row['imageUrl']) if pd.notna(row['imageUrl']) else ""
    video_url = str(row['videoUrl']) if pd.notna(row['videoUrl']) else ""
    
    # 添加到唯一值追蹤器
    if body_part:
        # 記錄這個部位對應的文檔ID
        if body_part not in exercise_ids_by_bodypart:
            exercise_ids_by_bodypart[body_part] = set()
        exercise_ids_by_bodypart[body_part].add(str(index))  # 使用索引作為唯一標識符
        
        # 維護唯一部位列表
        if body_part not in unique_body_parts:
            unique_body_parts[body_part] = 0  # 初始化計數為0，後面再計算
    
    if equipment:
        # 記錄這個器材對應的文檔ID
        if equipment not in exercise_ids_by_equipment:
            exercise_ids_by_equipment[equipment] = set()
        exercise_ids_by_equipment[equipment].add(str(index))
        
        # 維護唯一器材列表
        if equipment not in unique_equipments:
            unique_equipments[equipment] = 0
    
    if exercise_type:
        # 记录这个训练类型对应的文档ID
        if exercise_type not in exercise_ids_by_type:
            exercise_ids_by_type[exercise_type] = set()
        exercise_ids_by_type[exercise_type].add(str(index))
        
        # 维护唯一训练类型列表
        if exercise_type not in unique_types:
            unique_types[exercise_type] = 0  # 初始化计数为0，后面再计算
    
    if joint_type:
        # 记录这个关节类型对应的文档ID
        if joint_type not in exercise_ids_by_jointtype:
            exercise_ids_by_jointtype[joint_type] = set()
        exercise_ids_by_jointtype[joint_type].add(str(index))
        
        # 维护唯一关节类型列表
        if joint_type not in unique_joint_types:
            unique_joint_types[joint_type] = 0  # 初始化计数为0，后面再计算
    
    # 創建exercise文檔
    doc_ref = db.collection('exercise').document()
    batch.set(doc_ref, {
        'name': name,
        'nameEn': name_en,
        'bodyParts': body_parts_array,
        'type': exercise_type,
        'equipment': equipment,
        'jointType': joint_type,
        'level1': level1,
        'level2': level2,
        'level3': level3,
        'level4': level4,
        'level5': level5,
        'actionName': action_name,
        'description': description,
        'imageUrl': image_url,
        'videoUrl': video_url,
        'apps': [],  # 新增空的apps數組
        'createdAt': firestore.SERVER_TIMESTAMP
    })
    
    current_batch += 1
    total_count += 1
    
    # 當達到批量處理上限時提交
    if current_batch >= batch_size:
        print(f"提交批次 {total_count//batch_size}，共 {current_batch} 筆資料")
        batch.commit()
        time.sleep(2)  # 避免達到API寫入限制
        current_batch = 0
        batch = db.batch()

# 提交剩餘的資料
if current_batch > 0:
    print(f"提交最後一批，共 {current_batch} 筆資料")
    batch.commit()

print(f"成功導入 {total_count} 筆健身動作資料")
print("開始創建輔助集合...")

# 計算實際的計數值
for body_part in unique_body_parts:
    unique_body_parts[body_part] = len(exercise_ids_by_bodypart[body_part])

for equipment in unique_equipments:
    unique_equipments[equipment] = len(exercise_ids_by_equipment[equipment])

for exercise_type in unique_types:
    unique_types[exercise_type] = len(exercise_ids_by_type[exercise_type])

for joint_type in unique_joint_types:
    unique_joint_types[joint_type] = len(exercise_ids_by_jointtype[joint_type])

# 步驟6: 創建輔助集合
# bodyParts集合
batch = db.batch()
count = 0
for body_part, part_count in unique_body_parts.items():
    if count >= batch_size:
        batch.commit()
        time.sleep(1)
        batch = db.batch()
        count = 0
    
    doc_ref = db.collection('bodyParts').document()
    batch.set(doc_ref, {
        'name': body_part,
        'count': part_count,
        'description': ""
    })
    count += 1

if count > 0:
    batch.commit()
print(f"成功創建 {len(unique_body_parts)} 個部位記錄")

# equipments集合
batch = db.batch()
count = 0
for equipment, equip_count in unique_equipments.items():
    if count >= batch_size:
        batch.commit()
        time.sleep(1)
        batch = db.batch()
        count = 0
    
    doc_ref = db.collection('equipments').document()
    batch.set(doc_ref, {
        'name': equipment,
        'count': equip_count,
        'description': ""
    })
    count += 1

if count > 0:
    batch.commit()
print(f"成功創建 {len(unique_equipments)} 個器材記錄")

# exerciseTypes集合
batch = db.batch()
for exercise_type, type_count in unique_types.items():
    doc_ref = db.collection('exerciseTypes').document()
    batch.set(doc_ref, {
        'name': exercise_type,
        'count': type_count,
        'description': ""
    })
batch.commit()
print(f"成功創建 {len(unique_types)} 個訓練類型記錄")

# jointTypes集合
batch = db.batch()
for joint_type, joint_count in unique_joint_types.items():
    doc_ref = db.collection('jointTypes').document()
    batch.set(doc_ref, {
        'name': joint_type,
        'count': joint_count,
        'description': ""
    })
batch.commit()
print(f"成功創建 {len(unique_joint_types)} 個關節類型記錄")

print("所有資料導入完成！")