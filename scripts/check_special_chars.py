#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
檢查動作名稱中的特殊字符
"""

import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

# 載入資料
with open('database_export/exercises.json', 'r', encoding='utf-8') as f:
    exercises = json.load(f)

# 檢查單引號
names_with_quote = [ex['name'] for ex in exercises if "'" in ex['name']]
print(f"✅ 含單引號的動作數: {len(names_with_quote)}")
if names_with_quote:
    print("範例:")
    for name in names_with_quote[:5]:
        print(f"  - {name}")
    print()

# 檢查斜線
names_with_slash = [ex['name'] for ex in exercises if "/" in ex['name'] or "／" in ex['name']]
print(f"✅ 含斜線的動作數: {len(names_with_slash)}")
if names_with_slash:
    print("範例:")
    for name in names_with_slash[:5]:
        print(f"  - {name}")
    print()

# 檢查其他特殊字符
special_chars = ['\\', '"', ';', '--', '/*', '*/']
for char in special_chars:
    names_with_char = [ex['name'] for ex in exercises if char in ex['name']]
    if names_with_char:
        print(f"⚠️ 含 '{char}' 的動作數: {len(names_with_char)}")
        print("範例:")
        for name in names_with_char[:3]:
            print(f"  - {name}")
        print()

print("=" * 80)
print("結論：")
print(f"  - 斜線 (/, ／) 在 SQL 字串中是安全的，不需要轉義")
print(f"  - 單引號需要轉義為兩個單引號 ('')")
print(f"  - escape_sql_string() 函數已經處理了單引號轉義")

