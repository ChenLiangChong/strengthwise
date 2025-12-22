#!/usr/bin/env python3
"""
从代码中分析 Firestore 集合和字段结构
无需 Firebase 认证，通过分析代码文件来推断数据库结构
"""

import os
import re
import json
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Set

def find_dart_files(root_dir: str) -> List[Path]:
    """查找所有 Dart 文件"""
    dart_files = []
    for root, dirs, files in os.walk(root_dir):
        # 跳过 build 和 .dart_tool 目录
        dirs[:] = [d for d in dirs if d not in ['build', '.dart_tool', '.git']]
        for file in files:
            if file.endswith('.dart'):
                dart_files.append(Path(root) / file)
    return dart_files

def extract_collection_names(content: str) -> Set[str]:
    """从代码中提取集合名称"""
    collections = set()
    
    # 匹配 .collection('collectionName') 或 .collection("collectionName")
    patterns = [
        r"\.collection\(['\"]([^'\"]+)['\"]\)",
        r"collection\(['\"]([^'\"]+)['\"]\)",
        r"CollectionReference<.*>.*['\"]([^'\"]+)['\"]",
    ]
    
    for pattern in patterns:
        matches = re.findall(pattern, content)
        collections.update(matches)
    
    return collections

def extract_field_names(content: str, collection_name: str) -> Dict[str, List[str]]:
    """从 Model 类中提取字段名称"""
    fields = defaultdict(list)
    
    # 查找 Model 类的 fromMap 方法
    # 匹配 map['fieldName'] 或 map["fieldName"]
    field_pattern = r"map\[['\"]([^'\"]+)['\"]\]"
    matches = re.findall(field_pattern, content)
    
    for match in matches:
        fields[collection_name].append(match)
    
    # 查找 toMap 方法中的字段
    # 匹配 'fieldName': 或 "fieldName":
    to_map_pattern = r"['\"]([^'\"]+)['\"]\s*:"
    to_map_matches = re.findall(to_map_pattern, content)
    fields[collection_name].extend(to_map_matches)
    
    return fields

def analyze_model_file(file_path: Path) -> Dict[str, List[str]]:
    """分析单个 Model 文件"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 提取集合名称（从注释或类名推断）
        collection_name = None
        
        # 尝试从文件名推断集合名称
        filename = file_path.stem
        if 'user' in filename.lower():
            collection_name = 'users'
        elif 'workout' in filename.lower() and 'template' in filename.lower():
            collection_name = 'workoutPlans'
        elif 'workout' in filename.lower() and 'record' in filename.lower():
            collection_name = 'workoutPlans'  # 可能也是 workoutPlans
        elif 'note' in filename.lower():
            collection_name = 'notes'
        elif 'exercise' in filename.lower():
            collection_name = 'exercise'  # 或 exercises
        
        if collection_name:
            fields = extract_field_names(content, collection_name)
            return fields
        
        return {}
    except Exception as e:
        print(f"  [WARN] 分析文件失败 {file_path}: {e}")
        return {}

def analyze_service_file(file_path: Path) -> Set[str]:
    """分析 Service 文件，提取集合名称"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        collections = extract_collection_names(content)
        return collections
    except Exception as e:
        print(f"  [WARN] 分析文件失败 {file_path}: {e}")
        return set()

def main():
    print("=" * 60)
    print("从代码分析 Firestore 集合结构")
    print("项目: strengthwise")
    print("=" * 60)
    
    lib_dir = Path('lib')
    if not lib_dir.exists():
        print("[ERROR] lib 目录不存在")
        return
    
    # 查找所有 Dart 文件
    dart_files = find_dart_files('lib')
    print(f"\n找到 {len(dart_files)} 个 Dart 文件")
    
    # 分析集合和字段
    all_collections = set()
    collection_fields = defaultdict(set)
    
    # 从 firestore.rules 提取集合
    rules_file = Path('firestore.rules')
    if rules_file.exists():
        print("\n分析 firestore.rules...")
        with open(rules_file, 'r', encoding='utf-8') as f:
            rules_content = f.read()
            # 匹配 match /collectionName/
            rule_collections = re.findall(r'match\s+/([^/]+)/', rules_content)
            all_collections.update(rule_collections)
            print(f"  从规则文件找到 {len(rule_collections)} 个集合")
    
    # 分析 Service 文件
    print("\n分析 Service 文件...")
    service_files = [f for f in dart_files if 'service' in str(f).lower()]
    for service_file in service_files:
        collections = analyze_service_file(service_file)
        all_collections.update(collections)
        if collections:
            print(f"  {service_file.name}: {collections}")
    
    # 分析 Model 文件
    print("\n分析 Model 文件...")
    model_files = [f for f in dart_files if 'model' in str(f).lower()]
    for model_file in model_files:
        fields_dict = analyze_model_file(model_file)
        for collection, fields in fields_dict.items():
            all_collections.add(collection)
            collection_fields[collection].update(fields)
        if fields_dict:
            print(f"  {model_file.name}: {list(fields_dict.keys())}")
    
    # 生成报告
    print("\n" + "=" * 60)
    print("分析结果")
    print("=" * 60)
    
    report = {
        'collections': {}
    }
    
    for collection_name in sorted(all_collections):
        fields = sorted(list(collection_fields[collection_name]))
        report['collections'][collection_name] = {
            'name': collection_name,
            'fields': fields,
            'field_count': len(fields)
        }
        
        print(f"\n[集合] {collection_name}")
        print(f"  字段数量: {len(fields)}")
        if fields:
            print(f"  字段列表: {', '.join(fields[:10])}")
            if len(fields) > 10:
                print(f"  ... 还有 {len(fields) - 10} 个字段")
        else:
            print("  (未找到字段信息)")
    
    # 保存 JSON 报告
    output_file = 'firestore_analysis_from_code.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, ensure_ascii=False, indent=2)
    
    print(f"\n报告已保存到: {output_file}")
    
    # 生成 Markdown 报告
    markdown_file = 'firestore_analysis_from_code.md'
    with open(markdown_file, 'w', encoding='utf-8') as f:
        f.write("# Firestore 集合结构分析报告（从代码分析）\n\n")
        f.write("**注意**: 这是从代码中推断的结构，可能与实际数据库有所不同。\n\n")
        f.write("## 集合概览\n\n")
        f.write("| 集合名称 | 字段数量 |\n")
        f.write("|---------|---------|\n")
        
        for collection_name in sorted(all_collections):
            field_count = len(collection_fields[collection_name])
            f.write(f"| `{collection_name}` | {field_count} |\n")
        
        f.write("\n## 详细字段结构\n\n")
        
        for collection_name in sorted(all_collections):
            fields = sorted(list(collection_fields[collection_name]))
            f.write(f"### {collection_name}\n\n")
            
            if fields:
                f.write("| 字段名称 |\n")
                f.write("|---------|\n")
                for field in fields:
                    f.write(f"| `{field}` |\n")
            else:
                f.write("*未找到字段信息*\n")
            
            f.write("\n")
    
    print(f"Markdown 报告已保存到: {markdown_file}")
    print("\n分析完成！")
    print("\n提示: 要获取实际数据库结构，请设置 Firebase 认证后运行 analyze_firestore.py")

if __name__ == '__main__':
    main()

