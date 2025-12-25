#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import sys
from dotenv import load_dotenv

sys.stdout.reconfigure(encoding='utf-8')

# 獲取專案根目錄
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
ENV_FILE = os.path.join(PROJECT_ROOT, '.env')

print(f"專案根目錄: {PROJECT_ROOT}")
print(f".env 文件路徑: {ENV_FILE}")
print(f".env 是否存在: {os.path.exists(ENV_FILE)}")
print("")

# 載入環境變數
load_dotenv(ENV_FILE)

# 顯示所有環境變數（隱藏敏感資訊）
print("環境變數檢查：")
print("-" * 60)

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if url:
    print(f"OK SUPABASE_URL: {url[:30]}...")
else:
    print("FAIL SUPABASE_URL: NOT FOUND")

if key:
    print(f"OK SUPABASE_SERVICE_ROLE_KEY: {key[:20]}...")
else:
    print("FAIL SUPABASE_SERVICE_ROLE_KEY: NOT FOUND")

print("")
print("嘗試讀取 .env 文件內容（前 10 行）：")
print("-" * 60)
try:
    with open(ENV_FILE, 'r', encoding='utf-8') as f:
        lines = f.readlines()[:10]
        for i, line in enumerate(lines, 1):
            # 隱藏實際值
            if '=' in line and not line.strip().startswith('#'):
                parts = line.split('=', 1)
                key_part = parts[0].strip()
                value_part = parts[1].strip() if len(parts) > 1 else ''
                if value_part:
                    print(f"{i}. {key_part}=*** (長度: {len(value_part)})")
                else:
                    print(f"{i}. {key_part}= (空值)")
            else:
                print(f"{i}. {line.strip()}")
except Exception as e:
    print(f"讀取失敗: {e}")

