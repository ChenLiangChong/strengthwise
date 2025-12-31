#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
設置教練-學員綁定關係

This script will:
1. 連接到 Supabase
2. 查詢用戶資料
3. 創建教練-學員綁定關係

Usage:
    python scripts/setup_coaching_relationship.py
"""

import sys
import os
from dotenv import load_dotenv
from supabase import create_client, Client

# Set UTF-8 output
sys.stdout.reconfigure(encoding='utf-8')

# Get project root and load environment variables
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
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

# Supabase configuration
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")

if not SUPABASE_URL or not SUPABASE_ANON_KEY:
    print("❌ Error: SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env file")
    sys.exit(1)

# Initialize Supabase client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)

def main():
    print("\n" + "="*80)
    print("🏋️ StrengthWise - 設置教練-學員綁定關係")
    print("="*80 + "\n")
    
    # 步驟 1：查詢所有用戶
    print("📋 步驟 1：查詢所有用戶...")
    try:
        response = supabase.table('users').select('id, email, display_name, is_coach, is_student').execute()
        users = response.data
        
        print(f"\n✅ 找到 {len(users)} 個用戶：")
        for i, user in enumerate(users, 1):
            print(f"  {i}. {user['email']}")
            print(f"     ID: {user['id']}")
            print(f"     顯示名稱: {user.get('display_name', 'NULL')}")
            print(f"     is_coach: {user.get('is_coach', False)}")
            print(f"     is_student: {user.get('is_student', False)}")
            print()
        
    except Exception as e:
        print(f"❌ 查詢用戶失敗: {e}")
        sys.exit(1)
    
    # 找到教練和學員
    coach_user = None
    client_user = None
    
    for user in users:
        if user['email'] == 'charlie19960414@gmail.com':
            coach_user = user
        elif user['email'] == 'charlie8519960414@gmail.com':
            client_user = user
    
    if not coach_user:
        print("❌ 找不到教練用戶 (charlie19960414@gmail.com)")
        sys.exit(1)
    
    if not client_user:
        print("❌ 找不到學員用戶 (charlie8519960414@gmail.com)")
        sys.exit(1)
    
    coach_id = coach_user['id']
    client_id = client_user['id']
    
    print(f"✅ 找到教練: {coach_user['email']} (ID: {coach_id})")
    print(f"✅ 找到學員: {client_user['email']} (ID: {client_id})\n")
    
    # 步驟 2：設定教練身份
    print("📋 步驟 2：設定教練身份...")
    try:
        supabase.table('users').update({
            'is_coach': True
        }).eq('id', coach_id).execute()
        print(f"✅ 已將 {coach_user['email']} 設為教練\n")
    except Exception as e:
        print(f"❌ 設定教練身份失敗: {e}")
        sys.exit(1)
    
    # 步驟 3：創建綁定關係
    print("📋 步驟 3：創建綁定關係...")
    try:
        # 先檢查是否已存在
        existing = supabase.table('coaching_relationships').select('*').eq('coach_id', coach_id).eq('client_id', client_id).execute()
        
        if existing.data and len(existing.data) > 0:
            print(f"⚠️  綁定關係已存在！")
            relationship = existing.data[0]
        else:
            response = supabase.table('coaching_relationships').insert({
                'coach_id': coach_id,
                'client_id': client_id,
                'status': 'active',
                'notes': '測試學員 - Python 腳本創建'
            }).execute()
            relationship = response.data[0]
            print(f"✅ 成功創建綁定關係！")
        
        print(f"\n綁定關係詳情：")
        print(f"  ID: {relationship['id']}")
        print(f"  教練 ID: {relationship['coach_id']}")
        print(f"  學員 ID: {relationship['client_id']}")
        print(f"  狀態: {relationship['status']}")
        print(f"  備註: {relationship.get('notes', 'N/A')}")
        print(f"  創建時間: {relationship['created_at']}")
        
    except Exception as e:
        print(f"❌ 創建綁定關係失敗: {e}")
        sys.exit(1)
    
    # 步驟 4：驗證結果
    print("\n" + "="*80)
    print("📋 步驟 4：驗證綁定關係...")
    try:
        # 查詢所有綁定關係（含 JOIN）
        relationships = supabase.table('coaching_relationships').select('*, coach:coach_id(email, display_name), client:client_id(email, display_name)').eq('coach_id', coach_id).execute()
        
        print(f"\n✅ 教練 {coach_user['email']} 共有 {len(relationships.data)} 個學員：\n")
        for i, rel in enumerate(relationships.data, 1):
            print(f"  {i}. 學員: {rel['client']['email']}")
            print(f"     狀態: {rel['status']}")
            print(f"     備註: {rel.get('notes', 'N/A')}")
            print()
        
    except Exception as e:
        print(f"⚠️  驗證查詢失敗（可能是 RLS 限制）: {e}")
        print("   請在 Supabase Dashboard SQL Editor 中手動驗證")
    
    print("="*80)
    print("✅ Phase 1.3 完成！")
    print("="*80 + "\n")

if __name__ == "__main__":
    main()

