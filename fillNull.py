import pandas as pd
import numpy as np
import re
from deep_translator import GoogleTranslator
import time

# 載入CSV文件
print("正在讀取CSV文件...")
df = pd.read_csv('exercises.csv')
original_df = df.copy()  # 保存原始資料用於比較

print(f"資料總行數: {len(df)}")
for column in df.columns:
    missing = df[column].isna().sum()
    print(f"{column}: 缺失值數量 {missing} ({missing/len(df)*100:.2f}%)")

# 中文動作名稱關鍵詞映射表
bodypart_keywords = {
    '胸部': ['胸', '推舉', '夾胸', '飛鳥', '臥推'],
    '背部': ['背', '划船', '引體', '拉力', '拉背', '滑輪下拉', '肩胛', '屈體', '聳肩'],
    '腿部': ['腿', '深蹲', '硬舉', '分腿', '蹲', '腘繩肌', '抬腿', '小腿', '膝蓋', '髖'],
    '肩部': ['肩', '聳', '側平舉', '前平舉', '後平舉', '肩推'],
    '手臂': ['臂', '二頭', '三頭', '屈臂', '伸臂', '彎舉', '臂屈伸'],
    '腹部': ['腹', '卷腹', '仰臥起坐', '平板', '核心'],
    '臀部': ['臀', '橋式'],
    '全身': ['全身', '燕飛', '劈蹲', '波比', '爆發']
}

equipment_keywords = {
    '啞鈴': ['啞鈴', '啞铃'],
    '槓鈴': ['槓鈴', '杠鈴', '桿鈴', '杆鈴', '長槓'],
    '壺鈴': ['壺鈴', '壶铃'],
    '機器': ['機器', '器械', '機械', '滑輪', '機'],
    '纜繩': ['纜繩', '繩索', '绳索'],
    '彈力帶': ['彈力帶', '阻力帶', '彈力绳'],
    '健身球': ['健身球', '瑜伽球', '藥球'],
    '拉力器': ['拉力器'],
    '引體向上器': ['引體向上器', '單杠', '雙杠'],
    '健身椅': ['健身椅', '臥推椅', '訓練椅'],
    '跑步機': ['跑步機'],
    '踏步機': ['踏步機', '橢圓機'],
    '單車': ['單車', '自行車', '動感單車'],
    '跳繩': ['跳繩'],
    '徒手': ['徒手']
}

exercise_type_keywords = {
    '重訓': ['舉', '推', '拉', '蹲', '屈', '伸', '硬舉', '舉重', '健美', '肌力', '力量', '啞鈴', '槓鈴', '機器'],
    '有氧': ['跑', '跳', '騎', '走', '健走', '有氧', '心肺', '踏步', '單車', '橢圓機', '跳繩'],
    '伸展': ['伸展', '拉伸', '柔軟', '瑜伽', '拉申', '伸直', '伸展', '放鬆']
}

# 1. 處理英文翻譯欄位
missing_english = df['英文翻譯'].isna()
if missing_english.any():
    print(f"\n開始處理英文翻譯，缺失值數量: {missing_english.sum()}")
    
    # 創建中文到英文的映射字典
    chinese_to_english = {}
    for name, eng in zip(df['Name'], df['英文翻譯']):
        if pd.notna(name) and pd.notna(eng):
            chinese_to_english[name] = eng
    
    # 英文翻譯逐一處理
    for idx in df[missing_english].index:
        chinese_name = df.loc[idx, 'Name']
        # 檢查是否為有效字符串
        if not isinstance(chinese_name, str):
            print(f"跳過無效名稱 (NaN 或非字符串值)")
            continue
        
        # 如果已經有相同動作的翻譯
        if chinese_name in chinese_to_english:
            df.loc[idx, '英文翻譯'] = chinese_to_english[chinese_name]
            print(f"從現有資料填充英文翻譯: {chinese_name} -> {chinese_to_english[chinese_name]}")
        else:
            # 動作名稱組合詞的翻譯處理
            words = re.findall(r'[\w]+', chinese_name)
            translated_words = []
            for word in words:
                for existing_name, eng_name in chinese_to_english.items():
                    if word in existing_name:
                        translated_words.append(eng_name)
                        break
            
            if translated_words:
                df.loc[idx, '英文翻譯'] = " ".join(translated_words)
                print(f"組合翻譯: {chinese_name} -> {df.loc[idx, '英文翻譯']}")
            else:
                # 如果無法從現有資料推斷，則使用基本映射
                basic_translations = {
                    '啞鈴': 'Dumbbell',
                    '槓鈴': 'Barbell',
                    '機器': 'Machine',
                    '伸展': 'Stretch',
                    '臥推': 'Bench Press',
                    '深蹲': 'Squat',
                    '硬舉': 'Deadlift',
                    '划船': 'Row',
                    '推舉': 'Press',
                    '彎舉': 'Curl',
                    '夾胸': 'Fly',
                    '引體向上': 'Pull-up',
                    '屈臂': 'Curl',
                    '伸臂': 'Extension',
                    '舉腿': 'Leg Raise',
                    '卷腹': 'Crunch',
                    '平板支撐': 'Plank'
                }
                
                eng_words = []
                for word, trans in basic_translations.items():
                    if word in chinese_name:
                        eng_words.append(trans)
                
                if eng_words:
                    df.loc[idx, '英文翻譯'] = " ".join(eng_words)
                    print(f"基本翻譯: {chinese_name} -> {df.loc[idx, '英文翻譯']}")
                else:
                    df.loc[idx, '英文翻譯'] = chinese_name  # 實在無法翻譯就保留原名
                    print(f"無法翻譯: {chinese_name}")

# 2. 處理部位欄位
missing_bodypart = df['部位'].isna()
if missing_bodypart.any():
    print(f"\n開始處理部位欄位，缺失值數量: {missing_bodypart.sum()}")
    
    # 創建查詢字典，根據已有數據推斷
    name_to_bodypart = {}
    for name, part in zip(df['Name'], df['部位']):
        if pd.notna(part) and pd.notna(name):
            name_to_bodypart[name] = part
    
    # 填充空值
    for idx in df[missing_bodypart].index:
        name = df.loc[idx, 'Name']
        # 檢查是否為有效字符串
        if not isinstance(name, str):
            print(f"跳過無效部位名稱 (NaN 或非字符串值)")
            continue
        
        if name in name_to_bodypart:
            df.loc[idx, '部位'] = name_to_bodypart[name]
            print(f"從現有資料填充部位: {name} -> {name_to_bodypart[name]}")
            continue
        
        # 根據關鍵詞推斷部位
        found = False
        for part, keywords in bodypart_keywords.items():
            if any(keyword in name for keyword in keywords):
                df.loc[idx, '部位'] = part
                print(f"根據關鍵詞推斷部位: {name} -> {part}")
                found = True
                break
        
        if not found:
            # 默認為全身
            df.loc[idx, '部位'] = '全身'
            print(f"找不到相關部位，設為全身: {name}")

# 3. 處理重訓／有氧／伸展欄位
missing_type = df['重訓／有氧／伸展'].isna()
if missing_type.any():
    print(f"\n開始處理重訓／有氧／伸展欄位，缺失值數量: {missing_type.sum()}")
    
    # 創建查詢字典
    name_to_type = {}
    for name, ex_type in zip(df['Name'], df['重訓／有氧／伸展']):
        if pd.notna(ex_type) and pd.notna(name):
            name_to_type[name] = ex_type
    
    # 填充空值
    for idx in df[missing_type].index:
        name = df.loc[idx, 'Name']
        # 檢查是否為有效字符串
        if not isinstance(name, str):
            print(f"跳過無效類型名稱 (NaN 或非字符串值)")
            continue
        
        if name in name_to_type:
            df.loc[idx, '重訓／有氧／伸展'] = name_to_type[name]
            print(f"從現有資料填充類型: {name} -> {name_to_type[name]}")
            continue
        
        # 根據關鍵詞推斷類型
        found = False
        for ex_type, keywords in exercise_type_keywords.items():
            if any(keyword in name for keyword in keywords):
                df.loc[idx, '重訓／有氧／伸展'] = ex_type
                print(f"根據關鍵詞推斷類型: {name} -> {ex_type}")
                found = True
                break
        
        if not found:
            # 根據器材推斷
            equipment = df.loc[idx, '器材']
            if pd.notna(equipment):
                if any(eq in equipment for eq in ['啞鈴', '槓鈴', '機器', '壺鈴', '纜繩']):
                    df.loc[idx, '重訓／有氧／伸展'] = '重訓'
                    print(f"根據器材推斷類型: {name} -> 重訓 (器材: {equipment})")
                    found = True
            
        if not found:
            # 默認為重訓
            df.loc[idx, '重訓／有氧／伸展'] = '重訓'
            print(f"找不到相關類型，設為重訓: {name}")

# 4. 處理器材欄位
missing_equipment = df['器材'].isna()
if missing_equipment.any():
    print(f"\n開始處理器材欄位，缺失值數量: {missing_equipment.sum()}")
    
    # 創建查詢字典
    name_to_equipment = {}
    for name, equip in zip(df['Name'], df['器材']):
        if pd.notna(equip) and pd.notna(name):
            name_to_equipment[name] = equip
    
    # 填充空值
    for idx in df[missing_equipment].index:
        name = df.loc[idx, 'Name']
        # 檢查是否為有效字符串
        if not isinstance(name, str):
            print(f"跳過無效器材名稱 (NaN 或非字符串值)")
            continue
        
        if name in name_to_equipment:
            df.loc[idx, '器材'] = name_to_equipment[name]
            print(f"從現有資料填充器材: {name} -> {name_to_equipment[name]}")
            continue
        
        # 根據關鍵詞推斷器材
        found = False
        for equipment, keywords in equipment_keywords.items():
            if any(keyword in name for keyword in keywords):
                df.loc[idx, '器材'] = equipment
                print(f"根據關鍵詞推斷器材: {name} -> {equipment}")
                found = True
                break
        
        if not found:
            # 默認為徒手
            df.loc[idx, '器材'] = '徒手'
            print(f"找不到相關器材，設為徒手: {name}")

# 5. 處理單關節／多關節欄位
missing_joint = df['單關節／多關節'].isna()
if missing_joint.any():
    print(f"\n開始處理單關節／多關節欄位，缺失值數量: {missing_joint.sum()}")
    
    # 單關節動作關鍵詞
    single_joint_keywords = ['二頭', '三頭', '肱二頭', '肱三頭', '平舉', '側舉', '前舉', '後舉', '屈伸', '收縮',
                            '伸展', '卷腹', '捲腹', '抬腿', '前抬', '鍛鍊', '孤立', '腘繩肌', '小腿']
    
    # 多關節動作關鍵詞
    multi_joint_keywords = ['深蹲', '硬舉', '臥推', '划船', '引體', '全身', '推舉', '推肩', '推胸', '推髖',
                          '綜合', '複合', '衝刺', '跳躍']
    
    # 部位到關節類型的映射
    bodypart_to_joint = {
        '胸部': 2,  # 多關節
        '背部': 2,  # 多關節
        '腿部': 2,  # 多關節
        '肩部': 1,  # 單關節
        '手臂': 1,  # 單關節
        '腹部': 1,  # 單關節
        '臀部': 1,  # 單關節
        '全身': 2   # 多關節
    }
    
    # 填充空值
    for idx in df[missing_joint].index:
        name = df.loc[idx, 'Name']
        # 檢查是否為有效字符串
        if not isinstance(name, str):
            print(f"跳過無效關節名稱 (NaN 或非字符串值)")
            continue
        
        bodypart = df.loc[idx, '部位']
        exercise_type = df.loc[idx, '重訓／有氧／伸展']
        
        # 如果是伸展或有氧，不適用單關節/多關節分類
        if pd.notna(exercise_type) and exercise_type in ['伸展', '有氧']:
            continue
        
        # 根據關鍵詞判斷
        if any(keyword in name for keyword in single_joint_keywords):
            df.loc[idx, '單關節／多關節'] = 1
            print(f"根據關鍵詞判斷為單關節: {name}")
            continue
            
        if any(keyword in name for keyword in multi_joint_keywords):
            df.loc[idx, '單關節／多關節'] = 2
            print(f"根據關鍵詞判斷為多關節: {name}")
            continue
        
        # 根據部位推斷
        if pd.notna(bodypart) and bodypart in bodypart_to_joint:
            df.loc[idx, '單關節／多關節'] = bodypart_to_joint[bodypart]
            print(f"根據部位推斷關節類型: {name} ({bodypart}) -> {bodypart_to_joint[bodypart]}")
            continue
        
        # 默認設為多關節
        df.loc[idx, '單關節／多關節'] = 2
        print(f"找不到相關關節類型，默認設為多關節: {name}")

# 在儲存更新的CSV之前，修改欄位名稱以匹配Firebase結構
# 將欄位名稱映射到Firebase字段名稱
column_mapping = {
    'Name': 'name',
    '英文翻譯': 'nameEn',
    '部位': 'bodyParts',
    '重訓／有氧／伸展': 'type',
    '器材': 'equipment',
    '單關節／多關節': 'jointType'
}

# 重命名欄位
df = df.rename(columns=column_mapping)

# 處理階層化的名稱
df['level1'] = ""        # 第一層分類
df['level2'] = ""        # 第二層分類
df['level3'] = ""        # 第三層分類
df['level4'] = ""        # 第四層分類
df['level5'] = ""        # 第五層分類
df['actionName'] = ""    # 最末層動作名稱

# 從名稱中提取分類信息
def extract_categories(name):
    if not isinstance(name, str):
        return "", "", "", "", "", ""
    
    # 將全角斜杠替換為半角斜杠以統一處理
    name = name.replace("／", "/")
    
    parts = name.split('/')
    # 清理分割後的部分
    clean_parts = [part.strip() for part in parts if part.strip()]
    
    # 初始化所有層級和動作名稱為空字符串
    category_levels = ["", "", "", "", ""]  # 5層分類
    action_name = ""
    
    if clean_parts:
        # 將最後一個部分設為動作名稱
        action_name = clean_parts[-1]
        
        # 處理分類層級（除了最後一個部分）
        category_parts = clean_parts[:-1]
        
        # 填充分類層級（最多5層）
        for i, part in enumerate(category_parts):
            if i < 5:  # 確保不超過5層
                category_levels[i] = part
    
    # 解包分類層級和動作名稱
    level1, level2, level3, level4, level5 = category_levels
    return level1, level2, level3, level4, level5, action_name

# 應用提取函數
for idx, row in df.iterrows():
    level1, level2, level3, level4, level5, action_name = extract_categories(row['name'])
    df.at[idx, 'level1'] = level1
    df.at[idx, 'level2'] = level2
    df.at[idx, 'level3'] = level3
    df.at[idx, 'level4'] = level4
    df.at[idx, 'level5'] = level5
    df.at[idx, 'actionName'] = action_name

# 添加缺少的欄位
df['description'] = ""  # 空描述
df['imageUrl'] = ""     # 空圖片URL
df['videoUrl'] = ""     # 空視頻URL
import datetime
df['createdAt'] = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")  # 當前時間作為創建時間

# 刪除不需要的欄位
if '健身App' in df.columns:
    df = df.drop('健身App', axis=1)
    print("已刪除不需要的 '健身App' 欄位")

# 儲存更新後的CSV
df.to_csv('exercises_updated.csv', index=False, encoding='utf-8-sig')
print("\n更新完成！新文件已儲存為 'exercises_updated.csv'")

# 顯示更新後的情況
print("\n更新後的資料情況:")
for column in df.columns:
    missing = df[column].isna().sum()
    print(f"{column}: 缺失值數量 {missing} ({missing/len(df)*100:.2f}%)")

# 顯示資料變化
print("\n資料變化統計:")
# 創建反向映射（新列名到舊列名）
reverse_mapping = {v: k for k, v in column_mapping.items()}

for column in df.columns:
    # 檢查是否為新添加的欄位
    if column in ['description', 'imageUrl', 'videoUrl', 'createdAt', 'level1', 'level2', 'level3', 'level4', 'level5', 'actionName']:
        print(f"{column}: 新增欄位")
        continue
    
    # 獲取對應的原始欄位名稱
    original_column = reverse_mapping.get(column)
    if original_column is not None:
        changes = (df[column] != original_df[original_column]).sum()
        print(f"{column}: 更新數量 {changes} ({changes/len(df)*100:.2f}%)")
    else:
        print(f"{column}: 新欄位，無法比較變化")