#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
StrengthWise 資料庫完整匯出工具
用於評估資料庫遷移可行性

此腳本會：
1. 連接 Firebase Firestore
2. 匯出所有集合的完整結構
3. 分析欄位使用情況
4. 評估查詢模式和潛在成本
5. 產生適合給資料庫專家看的詳細報告
"""

import sys
import os

# 設置輸出編碼為 UTF-8
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

import firebase_admin
from firebase_admin import credentials, firestore
import json
from collections import defaultdict
from typing import Dict, List, Set, Any, Optional
from datetime import datetime
from pathlib import Path

def initialize_firebase():
    """初始化 Firebase Admin SDK"""
    
    # 尋找服務帳號金鑰檔案
    key_file = 'strengthwise-service-account.json'
    key_path = Path(key_file)
    
    if not key_path.exists():
        print(f"[錯誤] 找不到服務帳號金鑰檔案: {key_file}")
        print("請確保檔案存在於專案根目錄")
        return False
    
    try:
        cred = credentials.Certificate(str(key_path))
        firebase_admin.initialize_app(cred, {'projectId': 'strengthwise-91f02'})
        print(f"✅ Firebase 初始化成功")
        return True
    except Exception as e:
        print(f"[錯誤] Firebase 初始化失敗: {e}")
        return False

def get_field_type(value: Any) -> str:
    """獲取欄位類型（繁體中文描述）"""
    if value is None:
        return "空值 (null)"
    elif isinstance(value, bool):
        return "布林值 (boolean)"
    elif isinstance(value, int):
        return "整數 (integer)"
    elif isinstance(value, float):
        return "浮點數 (float)"
    elif isinstance(value, str):
        return "字串 (string)"
    elif isinstance(value, list):
        if len(value) > 0:
            inner_type = get_field_type(value[0])
            return f"陣列 (array<{inner_type}>)"
        return "陣列 (array)"
    elif isinstance(value, dict):
        return "物件 (map/object)"
    elif hasattr(value, 'seconds'):  # Timestamp
        return "時間戳記 (timestamp)"
    elif hasattr(value, 'latitude'):  # GeoPoint
        return "地理位置 (geopoint)"
    else:
        return f"其他類型 ({type(value).__name__})"

def get_nested_fields(data: Dict[str, Any], prefix: str = "") -> Dict[str, Any]:
    """遞迴解析巢狀欄位結構"""
    fields = {}
    
    for key, value in data.items():
        field_path = f"{prefix}.{key}" if prefix else key
        field_type = get_field_type(value)
        
        fields[field_path] = {
            'type': field_type,
            'value': value
        }
        
        # 如果是物件，遞迴解析
        if isinstance(value, dict):
            nested = get_nested_fields(value, field_path)
            fields.update(nested)
        
        # 如果是陣列且包含物件，解析第一個物件的結構
        elif isinstance(value, list) and len(value) > 0 and isinstance(value[0], dict):
            nested = get_nested_fields(value[0], f"{field_path}[0]")
            fields.update(nested)
    
    return fields

def analyze_collection_deep(collection_name: str, max_docs: int = 1000) -> Dict[str, Any]:
    """深度分析集合結構"""
    print(f"\n📊 正在分析集合: {collection_name}")
    
    db = firestore.client()
    collection_ref = db.collection(collection_name)
    
    try:
        # 獲取文檔
        docs = list(collection_ref.limit(max_docs).stream())
        total_docs = len(docs)
        
        print(f"   找到 {total_docs} 個文檔")
        
        if total_docs == 0:
            return {
                'name': collection_name,
                'document_count': 0,
                'fields': {},
                'samples': []
            }
        
        # 分析欄位
        field_stats = defaultdict(lambda: {
            'types': set(),
            'null_count': 0,
            'non_null_count': 0,
            'sample_values': [],
            'nested_fields': set()
        })
        
        sample_docs = []
        doc_ids = []
        
        for doc in docs:
            doc_data = doc.to_dict()
            doc_ids.append(doc.id)
            
            # 保存前 5 個完整文檔作為範例
            if len(sample_docs) < 5:
                sample_docs.append({
                    'id': doc.id,
                    'data': doc_data
                })
            
            # 獲取所有欄位（包含巢狀）
            all_fields = get_nested_fields(doc_data)
            
            for field_path, field_info in all_fields.items():
                field_value = field_info['value']
                field_type = field_info['type']
                
                field_stats[field_path]['types'].add(field_type)
                
                if field_value is None:
                    field_stats[field_path]['null_count'] += 1
                else:
                    field_stats[field_path]['non_null_count'] += 1
                    
                    # 保存範例值（最多 5 個）
                    if len(field_stats[field_path]['sample_values']) < 5:
                        if isinstance(field_value, (str, int, float, bool)):
                            field_stats[field_path]['sample_values'].append(field_value)
                        elif isinstance(field_value, list):
                            field_stats[field_path]['sample_values'].append(f"[陣列, {len(field_value)} 項]")
                        elif isinstance(field_value, dict):
                            field_stats[field_path]['sample_values'].append(f"{{物件, {len(field_value)} 欄位}}")
                        elif hasattr(field_value, 'seconds'):
                            # Timestamp
                            dt = datetime.fromtimestamp(field_value.seconds)
                            field_stats[field_path]['sample_values'].append(dt.strftime('%Y-%m-%d %H:%M:%S'))
        
        # 格式化欄位統計
        fields_info = {}
        for field_path, stats in field_stats.items():
            occurrence_count = stats['null_count'] + stats['non_null_count']
            occurrence_rate = round(occurrence_count / total_docs * 100, 2)
            null_rate = round(stats['null_count'] / occurrence_count * 100, 2) if occurrence_count > 0 else 0
            
            fields_info[field_path] = {
                'types': sorted(list(stats['types'])),
                'occurrence_count': occurrence_count,
                'occurrence_rate': occurrence_rate,
                'null_count': stats['null_count'],
                'non_null_count': stats['non_null_count'],
                'null_rate': null_rate,
                'sample_values': stats['sample_values'][:5]
            }
        
        # 統計資訊
        total_fields = len(fields_info)
        avg_fields_per_doc = round(total_fields / total_docs, 2) if total_docs > 0 else 0
        
        print(f"   ✅ 分析完成: {total_fields} 個欄位（含巢狀）")
        
        return {
            'name': collection_name,
            'document_count': total_docs,
            'total_fields': total_fields,
            'avg_fields_per_doc': avg_fields_per_doc,
            'fields': fields_info,
            'sample_documents': sample_docs,
            'sample_doc_ids': doc_ids[:10]
        }
        
    except Exception as e:
        print(f"   ❌ 錯誤: {e}")
        return {
            'name': collection_name,
            'error': str(e)
        }

def estimate_query_costs(collections: Dict[str, Any]) -> Dict[str, Any]:
    """估算常見查詢模式的成本"""
    
    print("\n💰 正在估算查詢成本...")
    
    costs = {
        'description': '基於 Firestore 定價：讀取 $0.06/100K 次，寫入 $0.18/100K 次',
        'scenarios': []
    }
    
    # 分析 workoutPlans 的查詢模式
    if 'workoutPlans' in collections:
        workout_count = collections['workoutPlans'].get('document_count', 0)
        
        costs['scenarios'].append({
            'name': '用戶載入訓練計劃列表',
            'description': '每次打開 App 查詢 traineeId',
            'estimated_reads_per_query': min(50, workout_count),
            'frequency': '每用戶每日 5-10 次',
            'monthly_cost_per_user': round((50 * 8 * 30) / 100000 * 0.06, 4),
            'note': '若用戶有大量歷史記錄，成本會線性增加'
        })
        
        costs['scenarios'].append({
            'name': '完成一次訓練',
            'description': '讀取模板 + 更新記錄',
            'estimated_reads': 1,
            'estimated_writes': 1,
            'frequency': '每用戶每週 3-5 次',
            'monthly_cost_per_user': round((1 * 4 * 4) / 100000 * 0.06 + (1 * 4 * 4) / 100000 * 0.18, 4),
        })
    
    # 分析 exercises 的查詢模式
    if 'exercises' in collections or 'exercise' in collections:
        exercise_coll = 'exercises' if 'exercises' in collections else 'exercise'
        exercise_count = collections[exercise_coll].get('document_count', 0)
        
        costs['scenarios'].append({
            'name': '載入動作資料庫',
            'description': '用戶選擇動作時查詢所有動作',
            'estimated_reads_per_query': exercise_count,
            'frequency': '每用戶每週 1-2 次',
            'monthly_cost_per_user': round((exercise_count * 2 * 4) / 100000 * 0.06, 4),
            'note': f'共 {exercise_count} 個動作，每次都需要讀取全部'
        })
    
    # 分析 users 的查詢模式
    if 'users' in collections:
        costs['scenarios'].append({
            'name': '用戶登入',
            'description': '查詢用戶資料',
            'estimated_reads': 1,
            'frequency': '每用戶每日 1-3 次',
            'monthly_cost_per_user': round((1 * 2 * 30) / 100000 * 0.06, 4),
        })
    
    return costs

def generate_migration_recommendations(collections: Dict[str, Any]) -> List[str]:
    """產生資料庫遷移建議"""
    
    recommendations = []
    
    # 檢查 workoutPlans 的規模
    if 'workoutPlans' in collections:
        workout_count = collections['workoutPlans'].get('document_count', 0)
        if workout_count > 1000:
            recommendations.append({
                'priority': '高',
                'issue': f'workoutPlans 集合已有 {workout_count} 個文檔',
                'impact': '每次查詢用戶訓練計劃都需要掃描大量文檔，成本隨時間線性增長',
                'suggestion': '考慮使用關聯式資料庫（PostgreSQL）配合索引，或分片存儲歷史記錄'
            })
    
    # 檢查 exercises 的規模
    exercise_coll = None
    if 'exercises' in collections:
        exercise_coll = 'exercises'
    elif 'exercise' in collections:
        exercise_coll = 'exercise'
    
    if exercise_coll:
        exercise_count = collections[exercise_coll].get('document_count', 0)
        if exercise_count > 500:
            recommendations.append({
                'priority': '中',
                'issue': f'{exercise_coll} 集合有 {exercise_count} 個動作',
                'impact': '動作資料幾乎不變，但每次都要從 Firestore 讀取',
                'suggestion': '動作資料可以：1) 打包進 App 內，2) 使用 CDN 快取，3) 遷移到 PostgreSQL 並配合 Redis 快取'
            })
    
    # 檢查查詢模式
    recommendations.append({
        'priority': '高',
        'issue': 'Firestore 不支援複雜查詢',
        'impact': '需要客戶端排序/過濾，或創建大量複合索引',
        'suggestion': '關聯式資料庫（PostgreSQL）對複雜查詢有原生支援，且成本更可預測'
    })
    
    # 成本預測
    recommendations.append({
        'priority': '高',
        'issue': 'Firestore 成本隨用戶增長不可預測',
        'impact': '1000 活躍用戶可能產生每月 $50-200 的讀取成本',
        'suggestion': '關聯式資料庫（如 Supabase PostgreSQL）提供固定月費，更適合規模化'
    })
    
    return recommendations

def main():
    """主程式"""
    print("=" * 80)
    print("StrengthWise 資料庫完整匯出工具")
    print("=" * 80)
    print("用途: 評估資料庫遷移可行性\n")
    
    # 初始化 Firebase
    if not initialize_firebase():
        sys.exit(1)
    
    # 定義要分析的集合
    known_collections = [
        'users',
        'user',
        'workoutPlans',
        'bookings',
        'exercise',
        'exercises',
        'bodyParts',
        'exerciseTypes',
        'notes',
        'relationships',
        'availabilities',
    ]
    
    print(f"\n🔍 開始掃描 {len(known_collections)} 個已知集合...")
    
    # 分析所有集合
    db = firestore.client()
    collections_data = {}
    
    for collection_name in known_collections:
        try:
            # 先檢查集合是否存在
            test_query = db.collection(collection_name).limit(1).stream()
            if list(test_query):
                result = analyze_collection_deep(collection_name, max_docs=1000)
                if 'error' not in result:
                    collections_data[collection_name] = result
        except Exception as e:
            print(f"   ⚠️  集合 {collection_name} 不存在或無法存取")
            continue
    
    print(f"\n✅ 成功分析 {len(collections_data)} 個集合")
    
    # 估算查詢成本
    query_costs = estimate_query_costs(collections_data)
    
    # 產生遷移建議
    recommendations = generate_migration_recommendations(collections_data)
    
    # 組裝完整報告
    report = {
        'project_id': 'strengthwise-91f02',
        'export_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        'collections': collections_data,
        'query_cost_analysis': query_costs,
        'migration_recommendations': recommendations,
        'summary': {
            'total_collections': len(collections_data),
            'total_documents': sum(c.get('document_count', 0) for c in collections_data.values()),
            'total_fields': sum(c.get('total_fields', 0) for c in collections_data.values()),
        }
    }
    
    # 儲存 JSON 報告
    output_file = 'database_export_for_migration.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, ensure_ascii=False, indent=2, default=str)
    
    print(f"\n📄 JSON 報告已儲存: {output_file}")
    
    # 產生 Markdown 報告
    generate_markdown_report(report)
    
    # 列印摘要
    print("\n" + "=" * 80)
    print("📊 資料庫摘要")
    print("=" * 80)
    print(f"集合數量: {report['summary']['total_collections']}")
    print(f"文檔總數: {report['summary']['total_documents']}")
    print(f"欄位總數: {report['summary']['total_fields']}")
    print("\n💡 詳細報告請查看: docs/database_migration_analysis.md")
    print("=" * 80)

def generate_markdown_report(report: Dict[str, Any]):
    """產生 Markdown 格式的專業報告"""
    
    output_file = 'docs/database_migration_analysis.md'
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("# StrengthWise 資料庫遷移評估報告\n\n")
        f.write(f"**專案**: {report['project_id']}\n")
        f.write(f"**匯出時間**: {report['export_time']}\n")
        f.write(f"**目的**: 評估從 Firebase Firestore 遷移到其他資料庫的可行性\n\n")
        
        f.write("---\n\n")
        
        # 執行摘要
        f.write("## 📊 執行摘要\n\n")
        f.write(f"- **集合數量**: {report['summary']['total_collections']} 個\n")
        f.write(f"- **文檔總數**: {report['summary']['total_documents']} 個\n")
        f.write(f"- **欄位總數**: {report['summary']['total_fields']} 個（含巢狀欄位）\n\n")
        
        # 遷移建議
        f.write("## 🎯 遷移建議\n\n")
        
        for idx, rec in enumerate(report['migration_recommendations'], 1):
            f.write(f"### {idx}. {rec['issue']} `[優先級: {rec['priority']}]`\n\n")
            f.write(f"**影響**: {rec['impact']}\n\n")
            f.write(f"**建議**: {rec['suggestion']}\n\n")
        
        # 查詢成本分析
        f.write("## 💰 查詢成本分析\n\n")
        f.write(f"> {report['query_cost_analysis']['description']}\n\n")
        
        f.write("### 常見查詢場景\n\n")
        
        for scenario in report['query_cost_analysis']['scenarios']:
            f.write(f"#### {scenario['name']}\n\n")
            f.write(f"- **說明**: {scenario['description']}\n")
            f.write(f"- **頻率**: {scenario['frequency']}\n")
            
            if 'estimated_reads_per_query' in scenario:
                f.write(f"- **每次讀取數**: {scenario['estimated_reads_per_query']}\n")
            if 'estimated_reads' in scenario:
                f.write(f"- **讀取次數**: {scenario['estimated_reads']}\n")
            if 'estimated_writes' in scenario:
                f.write(f"- **寫入次數**: {scenario['estimated_writes']}\n")
            if 'monthly_cost_per_user' in scenario:
                f.write(f"- **每用戶月成本**: ${scenario['monthly_cost_per_user']}\n")
            if 'note' in scenario:
                f.write(f"- **備註**: {scenario['note']}\n")
            
            f.write("\n")
        
        # 集合詳細結構
        f.write("## 📁 集合詳細結構\n\n")
        
        for collection_name, collection_data in sorted(report['collections'].items()):
            if 'error' in collection_data:
                continue
            
            f.write(f"### {collection_name}\n\n")
            f.write(f"- **文檔數量**: {collection_data['document_count']}\n")
            f.write(f"- **欄位數量**: {collection_data['total_fields']}（含巢狀）\n")
            f.write(f"- **平均欄位數/文檔**: {collection_data['avg_fields_per_doc']}\n\n")
            
            # 欄位表格
            f.write("#### 欄位清單\n\n")
            f.write("| 欄位路徑 | 類型 | 出現率 | 空值率 | 範例值 |\n")
            f.write("|---------|------|--------|--------|--------|\n")
            
            for field_path, field_info in sorted(collection_data['fields'].items()):
                types_str = ", ".join(field_info['types'])
                occurrence_rate = f"{field_info['occurrence_rate']}%"
                null_rate = f"{field_info['null_rate']}%"
                
                # 範例值
                if field_info['sample_values']:
                    sample = str(field_info['sample_values'][0])
                    if len(sample) > 40:
                        sample = sample[:37] + "..."
                else:
                    sample = "-"
                
                # 處理 Markdown 表格中的特殊字符
                field_path_escaped = field_path.replace('|', '\\|')
                sample_escaped = sample.replace('|', '\\|')
                
                f.write(f"| `{field_path_escaped}` | {types_str} | {occurrence_rate} | {null_rate} | {sample_escaped} |\n")
            
            f.write("\n")
            
            # 範例文檔
            if collection_data.get('sample_documents'):
                f.write("#### 範例文檔\n\n")
                f.write("```json\n")
                f.write(json.dumps(collection_data['sample_documents'][0], ensure_ascii=False, indent=2, default=str))
                f.write("\n```\n\n")
        
        # 附錄
        f.write("---\n\n")
        f.write("## 📎 附錄\n\n")
        f.write("### 推薦的替代方案\n\n")
        f.write("1. **Supabase (PostgreSQL)**\n")
        f.write("   - 完整的 SQL 功能\n")
        f.write("   - 固定月費（$25 起）\n")
        f.write("   - 內建即時訂閱\n")
        f.write("   - 完整的 Flutter SDK\n\n")
        
        f.write("2. **自架 PostgreSQL + Redis**\n")
        f.write("   - 完全可控\n")
        f.write("   - 成本最低（長期）\n")
        f.write("   - 需要維護\n\n")
        
        f.write("3. **保留 Firestore 但優化**\n")
        f.write("   - 分離靜態資料（exercises）到 CDN\n")
        f.write("   - 實作更多客戶端快取\n")
        f.write("   - 定期封存歷史資料\n\n")
    
    print(f"📄 Markdown 報告已儲存: {output_file}")

if __name__ == '__main__':
    main()

