#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Firestore 集合和字段分析工具
分析 Firebase Firestore 数据库中的所有集合及其字段结构
"""

import sys
import os
# 设置输出编码为 UTF-8
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

import firebase_admin
from firebase_admin import credentials, firestore
import json
from collections import defaultdict
from typing import Dict, List, Set, Any

# 初始化 Firebase Admin SDK
import os
from pathlib import Path

def initialize_firebase():
    """初始化 Firebase，尝试多种认证方式"""
    
    # 方式 1: 尝试使用环境变量中的密钥文件路径
    cred_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
    if cred_path and Path(cred_path).exists():
        try:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred, {'projectId': 'strengthwise-91f02'})
            print(f"[OK] Using key file from environment variable: {cred_path}")
            return True
        except Exception as e:
            print(f"[WARN] Failed to use key file from environment: {e}")
    
    # 方式 2: 尝试项目目录中的常见密钥文件名
    common_key_files = [
        'strengthwise-service-account.json',
        'service-account-key.json',
        'firebase-service-account.json',
        'strengthwise-91f02-firebase-adminsdk.json',
    ]
    
    for key_file in common_key_files:
        key_path = Path(key_file)
        if key_path.exists():
            try:
                cred = credentials.Certificate(str(key_path))
                firebase_admin.initialize_app(cred, {'projectId': 'strengthwise-91f02'})
                print(f"[OK] Using key file: {key_file}")
                return True
            except Exception as e:
                print(f"[WARN] Failed to use key file {key_file}: {e}")
                continue
    
    # 方式 3: 尝试使用 Application Default Credentials (需要 gcloud)
    try:
        cred = credentials.ApplicationDefault()
        firebase_admin.initialize_app(cred, {'projectId': 'strengthwise-91f02'})
        print("[OK] Using Application Default Credentials")
        return True
    except Exception as e:
        print(f"[WARN] Application Default Credentials not available: {e}")
    
    # 所有方式都失败
    print("\n" + "=" * 60)
    print("[ERROR] 无法初始化 Firebase Admin SDK")
    print("=" * 60)
    print("\n请使用以下方法之一设置认证：")
    print("\n方法 1: 使用服务账号密钥文件（推荐）")
    print("  1. 在 Firebase Console 中生成服务账号密钥")
    print("  2. 将 JSON 文件保存到项目目录")
    print("  3. 文件名可以是: strengthwise-service-account.json")
    print("  4. 或设置环境变量 GOOGLE_APPLICATION_CREDENTIALS")
    print("\n方法 2: 使用 gcloud CLI")
    print("  运行: gcloud auth application-default login")
    print("\n详细说明请查看: FIREBASE_AUTH_SETUP.md")
    return False

if not initialize_firebase():
    sys.exit(1)

db = firestore.client()

def get_field_type(value: Any) -> str:
    """获取字段类型"""
    if value is None:
        return "null"
    elif isinstance(value, bool):
        return "boolean"
    elif isinstance(value, int):
        return "integer"
    elif isinstance(value, float):
        return "number"
    elif isinstance(value, str):
        return "string"
    elif isinstance(value, list):
        if len(value) > 0:
            return f"array<{get_field_type(value[0])}>"
        return "array"
    elif isinstance(value, dict):
        return "map"
    elif hasattr(value, 'seconds'):  # Timestamp
        return "timestamp"
    elif hasattr(value, 'latitude'):  # GeoPoint
        return "geopoint"
    else:
        return str(type(value).__name__)

def analyze_collection(collection_name: str, max_docs: int = 100) -> Dict[str, Any]:
    """分析单个集合的结构"""
    print(f"\n正在分析集合: {collection_name}...")
    
    collection_ref = db.collection(collection_name)
    
    # 获取文档数量
    try:
        docs = list(collection_ref.limit(max_docs).stream())
        total_docs = len(docs)
        
        if total_docs == 0:
            return {
                'name': collection_name,
                'document_count': 0,
                'fields': {},
                'sample_documents': []
            }
        
        # 分析字段
        field_stats = defaultdict(lambda: {
            'type': set(),
            'nullable': 0,
            'non_nullable': 0,
            'sample_values': []
        })
        
        sample_docs = []
        
        for doc in docs:
            doc_data = doc.to_dict()
            sample_docs.append({
                'id': doc.id,
                'data': doc_data
            })
            
            # 分析字段
            for field_name, field_value in doc_data.items():
                field_type = get_field_type(field_value)
                field_stats[field_name]['type'].add(field_type)
                
                if field_value is None:
                    field_stats[field_name]['nullable'] += 1
                else:
                    field_stats[field_name]['non_nullable'] += 1
                    # 保存示例值（最多3个）
                    if len(field_stats[field_name]['sample_values']) < 3:
                        if isinstance(field_value, (str, int, float, bool)):
                            field_stats[field_name]['sample_values'].append(field_value)
                        elif isinstance(field_value, list) and len(field_value) > 0:
                            field_stats[field_name]['sample_values'].append(f"[{len(field_value)} items]")
                        elif isinstance(field_value, dict):
                            field_stats[field_name]['sample_values'].append(f"{{...{len(field_value)} fields}}")
        
        # 格式化字段统计
        fields_info = {}
        for field_name, stats in field_stats.items():
            fields_info[field_name] = {
                'types': sorted(list(stats['type'])),
                'nullable_count': stats['nullable'],
                'non_nullable_count': stats['non_nullable'],
                'nullable_percentage': round(stats['nullable'] / total_docs * 100, 2),
                'sample_values': stats['sample_values']
            }
        
        return {
            'name': collection_name,
            'document_count': total_docs,
            'fields': fields_info,
            'sample_documents': sample_docs[:3]  # 只保存前3个示例文档
        }
        
    except Exception as e:
        print(f"  错误: {e}")
        return {
            'name': collection_name,
            'error': str(e)
        }

def get_all_collections() -> List[str]:
    """获取所有集合名称"""
    print("正在获取所有集合...")
    collections = []
    
    # Firestore 不直接提供列出所有集合的 API
    # 我们需要从代码中已知的集合，或者尝试访问常见的集合
    # 这里我们尝试从 firestore.rules 中提取，或者使用已知的集合列表
    
    # 已知的集合（从代码和文档中提取）
    known_collections = [
        'users',
        'user',  # 旧集合
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
    
    # 尝试访问每个集合，看是否存在
    for collection_name in known_collections:
        try:
            collection_ref = db.collection(collection_name)
            # 尝试获取一个文档来验证集合存在
            docs = list(collection_ref.limit(1).stream())
            collections.append(collection_name)
            print(f"  [OK] 找到集合: {collection_name}")
        except Exception as e:
            # 集合可能不存在或无法访问
            pass
    
    return collections

def main():
    print("=" * 60)
    print("Firestore 集合和字段分析工具")
    print("项目: strengthwise-91f02")
    print("=" * 60)
    
    # 获取所有集合
    collections = get_all_collections()
    
    if not collections:
        print("\n未找到任何集合。")
        return
    
    print(f"\n找到 {len(collections)} 个集合")
    
    # 分析每个集合
    results = {}
    for collection_name in collections:
        result = analyze_collection(collection_name)
        results[collection_name] = result
    
    # 生成报告
    print("\n" + "=" * 60)
    print("分析报告")
    print("=" * 60)
    
    report = {
        'project_id': 'strengthwise-91f02',
        'collections': results
    }
    
    # 保存为 JSON 文件
    output_file = 'firestore_analysis.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, ensure_ascii=False, indent=2, default=str)
    
    print(f"\n详细报告已保存到: {output_file}")
    
    # 打印摘要
    print("\n" + "=" * 60)
    print("集合摘要")
    print("=" * 60)
    
    for collection_name, result in results.items():
        if 'error' in result:
            print(f"\n❌ {collection_name}: {result['error']}")
            continue
        
        print(f"\n📁 {collection_name}")
        print(f"   文档数量: {result['document_count']}")
        print(f"   字段数量: {len(result['fields'])}")
        
        if result['fields']:
            print("   字段列表:")
            for field_name, field_info in sorted(result['fields'].items()):
                types_str = ", ".join(field_info['types'])
                nullable_pct = field_info['nullable_percentage']
                print(f"     - {field_name}: {types_str} (可空: {nullable_pct}%)")
    
    # 生成 Markdown 报告
    markdown_file = 'firestore_analysis.md'
    with open(markdown_file, 'w', encoding='utf-8') as f:
        f.write("# Firestore 数据库分析报告\n\n")
        f.write(f"**项目**: strengthwise-91f02\n")
        f.write(f"**分析时间**: {json.dumps(str(__import__('datetime').datetime.now()), ensure_ascii=False)}\n\n")
        
        f.write("## 集合概览\n\n")
        f.write("| 集合名称 | 文档数量 | 字段数量 |\n")
        f.write("|---------|---------|---------|\n")
        
        for collection_name, result in results.items():
            if 'error' not in result:
                f.write(f"| `{collection_name}` | {result['document_count']} | {len(result['fields'])} |\n")
        
        f.write("\n## 详细字段结构\n\n")
        
        for collection_name, result in results.items():
            if 'error' in result:
                f.write(f"### {collection_name}\n\n")
                f.write(f"**错误**: {result['error']}\n\n")
                continue
            
            f.write(f"### {collection_name}\n\n")
            f.write(f"**文档数量**: {result['document_count']}\n\n")
            
            if result['fields']:
                f.write("| 字段名称 | 类型 | 可空比例 | 示例值 |\n")
                f.write("|---------|------|---------|--------|\n")
                
                for field_name, field_info in sorted(result['fields'].items()):
                    types_str = " / ".join(field_info['types'])
                    nullable_pct = f"{field_info['nullable_percentage']}%"
                    sample_values = ", ".join([str(v) for v in field_info['sample_values'][:2]])
                    if not sample_values:
                        sample_values = "-"
                    
                    f.write(f"| `{field_name}` | {types_str} | {nullable_pct} | {sample_values} |\n")
            else:
                f.write("*无字段数据*\n")
            
            f.write("\n")
    
    print(f"\nMarkdown 报告已保存到: {markdown_file}")
    print("\n分析完成！")

if __name__ == '__main__':
    main()

