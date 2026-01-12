#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Database Schema 完整導出工具

導出 Supabase/PostgreSQL 資料庫的完整 Schema：
- Tables（表結構、欄位、約束、預設值）
- Triggers（觸發器定義）
- Functions（函數，包括 RPC、觸發器函數）
- RLS Policies（Row Level Security 規則）
- Views（視圖，包括 materialized views）
- Indexes（索引）
- Extensions（已啟用的擴展）
- Types（自定義類型）
- Foreign Keys（外鍵關係）

Usage:
    # 設定環境變數
    set DATABASE_URL=postgresql://postgres:xxx@db.xxx.supabase.co:5432/postgres
    
    # 或在 .env 中設定
    python scripts/tools/export_db_schema.py

Output:
    migrations/exported/
    ├── 00_extensions.sql
    ├── 01_types.sql
    ├── 02_tables.sql
    ├── 03_indexes.sql
    ├── 04_functions.sql
    ├── 05_triggers.sql
    ├── 06_rls_policies.sql
    ├── 07_views.sql
    └── schema_report.md
"""

import sys
import os
from datetime import datetime
from typing import List, Dict, Any, Optional
from collections import defaultdict

# Set UTF-8 output
sys.stdout.reconfigure(encoding='utf-8')

# Get project root
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))
OUTPUT_DIR = os.path.join(PROJECT_ROOT, 'migrations', 'exported')
MIGRATIONS_DIR = os.path.join(PROJECT_ROOT, 'migrations')

# Load environment variables
try:
    from dotenv import load_dotenv
    ENV_FILE = os.path.join(PROJECT_ROOT, '.env')
    if os.path.exists(ENV_FILE):
        with open(ENV_FILE, 'r', encoding='utf-8-sig') as f:
            env_content = f.read()
        temp_env = ENV_FILE + '.tmp'
        with open(temp_env, 'w', encoding='utf-8') as f:
            f.write(env_content)
        load_dotenv(temp_env)
        os.remove(temp_env)
except ImportError:
    print("⚠️  python-dotenv 未安裝，請確保環境變數已設定")

# Try to import psycopg2
try:
    import psycopg2
    from psycopg2.extras import RealDictCursor
except ImportError:
    print("❌ 請安裝 psycopg2-binary:")
    print("   pip install psycopg2-binary")
    sys.exit(1)


class DatabaseSchemaExporter:
    """數據庫 Schema 導出器"""
    
    # 排除的系統 schema
    EXCLUDED_SCHEMAS = [
        'pg_catalog', 'information_schema', 'pg_toast', 
        'pg_temp_1', 'pg_toast_temp_1',
        'supabase_functions', 'supabase_migrations',
        'graphql', 'graphql_public', 'realtime',
        'pgsodium', 'pgsodium_masks', 'vault',
        '_realtime', 'net', 'pgroonga'
    ]
    
    # 排除的系統表前綴
    EXCLUDED_TABLE_PREFIXES = [
        'pg_', 'sql_', '_', 'schema_migrations'
    ]
    
    def __init__(self, connection_string: str):
        self.connection_string = connection_string
        self.conn = None
        self.cursor = None
        
    def connect(self):
        """建立數據庫連接"""
        print("🔌 正在連接數據庫...")
        self.conn = psycopg2.connect(self.connection_string)
        self.cursor = self.conn.cursor(cursor_factory=RealDictCursor)
        print("✅ 連接成功")
        
    def disconnect(self):
        """關閉數據庫連接"""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        print("🔌 已斷開連接")
        
    def execute_query(self, query: str, params: tuple = None) -> List[Dict]:
        """執行查詢並返回結果"""
        self.cursor.execute(query, params)
        return [dict(row) for row in self.cursor.fetchall()]
    
    # ========================================================================
    # Extensions
    # ========================================================================
    def export_extensions(self) -> str:
        """導出已啟用的擴展"""
        print("\n📦 導出 Extensions...")
        
        query = """
            SELECT extname, extversion
            FROM pg_extension
            WHERE extname NOT IN ('plpgsql')
            ORDER BY extname;
        """
        extensions = self.execute_query(query)
        
        lines = [
            "-- ============================================================================",
            "-- Extensions（已啟用的擴展）",
            f"-- 導出時間：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            "-- ============================================================================",
            ""
        ]
        
        for ext in extensions:
            lines.append(f"-- {ext['extname']} (version: {ext['extversion']})")
            lines.append(f"CREATE EXTENSION IF NOT EXISTS \"{ext['extname']}\";")
            lines.append("")
        
        print(f"   找到 {len(extensions)} 個擴展")
        return "\n".join(lines)
    
    # ========================================================================
    # Types
    # ========================================================================
    def export_types(self) -> str:
        """導出自定義類型（ENUM 等）"""
        print("\n📋 導出 Types...")
        
        # 查詢 ENUM 類型
        query = """
            SELECT 
                t.typname AS type_name,
                n.nspname AS schema_name,
                ARRAY_AGG(e.enumlabel ORDER BY e.enumsortorder) AS enum_values
            FROM pg_type t
            JOIN pg_namespace n ON t.typnamespace = n.oid
            JOIN pg_enum e ON t.oid = e.enumtypid
            WHERE n.nspname = 'public'
            GROUP BY t.typname, n.nspname
            ORDER BY t.typname;
        """
        enums = self.execute_query(query)
        
        lines = [
            "-- ============================================================================",
            "-- Types（自定義類型）",
            f"-- 導出時間：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            "-- ============================================================================",
            ""
        ]
        
        for enum in enums:
            values = ", ".join([f"'{v}'" for v in enum['enum_values']])
            lines.append(f"-- ENUM: {enum['type_name']}")
            lines.append(f"DO $$ BEGIN")
            lines.append(f"    CREATE TYPE {enum['type_name']} AS ENUM ({values});")
            lines.append(f"EXCEPTION WHEN duplicate_object THEN NULL;")
            lines.append(f"END $$;")
            lines.append("")
        
        print(f"   找到 {len(enums)} 個自定義類型")
        return "\n".join(lines)
    
    # ========================================================================
    # Tables
    # ========================================================================
    def export_tables(self) -> str:
        """導出表結構"""
        print("\n📊 導出 Tables...")
        
        # 取得所有表
        tables_query = """
            SELECT 
                c.relname AS table_name,
                n.nspname AS schema_name,
                obj_description(c.oid) AS table_comment
            FROM pg_class c
            JOIN pg_namespace n ON c.relnamespace = n.oid
            WHERE c.relkind = 'r'
              AND n.nspname = 'public'
              AND c.relname NOT LIKE 'pg_%'
              AND c.relname NOT LIKE '_prisma_%'
            ORDER BY c.relname;
        """
        tables = self.execute_query(tables_query)
        
        lines = [
            "-- ============================================================================",
            "-- Tables（表結構）",
            f"-- 導出時間：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            "-- ============================================================================",
            ""
        ]
        
        for table in tables:
            table_name = table['table_name']
            lines.append(f"-- ============================================================================")
            lines.append(f"-- Table: {table_name}")
            lines.append(f"-- ============================================================================")
            
            # 取得欄位定義
            columns = self._get_table_columns(table_name)
            constraints = self._get_table_constraints(table_name)
            
            lines.append(f"CREATE TABLE IF NOT EXISTS {table_name} (")
            
            col_defs = []
            for col in columns:
                col_def = f"    {col['column_name']} {col['data_type']}"
                if col['character_maximum_length']:
                    col_def = f"    {col['column_name']} {col['udt_name']}({col['character_maximum_length']})"
                if col['is_nullable'] == 'NO':
                    col_def += " NOT NULL"
                if col['column_default']:
                    col_def += f" DEFAULT {col['column_default']}"
                col_defs.append(col_def)
            
            # 加入主鍵約束
            for cons in constraints:
                if cons['constraint_type'] == 'PRIMARY KEY':
                    col_defs.append(f"    PRIMARY KEY ({cons['column_name']})")
                elif cons['constraint_type'] == 'UNIQUE':
                    col_defs.append(f"    UNIQUE ({cons['column_name']})")
            
            lines.append(",\n".join(col_defs))
            lines.append(");")
            lines.append("")
            
            # RLS 啟用狀態
            rls_enabled = self._check_rls_enabled(table_name)
            if rls_enabled:
                lines.append(f"ALTER TABLE {table_name} ENABLE ROW LEVEL SECURITY;")
                lines.append("")
        
        print(f"   找到 {len(tables)} 個表")
        return "\n".join(lines)
    
    def _get_table_columns(self, table_name: str) -> List[Dict]:
        """取得表的欄位定義"""
        query = """
            SELECT 
                column_name,
                data_type,
                udt_name,
                character_maximum_length,
                is_nullable,
                column_default
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = %s
            ORDER BY ordinal_position;
        """
        return self.execute_query(query, (table_name,))
    
    def _get_table_constraints(self, table_name: str) -> List[Dict]:
        """取得表的約束"""
        query = """
            SELECT 
                tc.constraint_name,
                tc.constraint_type,
                kcu.column_name
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu 
                ON tc.constraint_name = kcu.constraint_name
                AND tc.table_schema = kcu.table_schema
            WHERE tc.table_schema = 'public'
              AND tc.table_name = %s
              AND tc.constraint_type IN ('PRIMARY KEY', 'UNIQUE')
            ORDER BY tc.constraint_type, kcu.ordinal_position;
        """
        return self.execute_query(query, (table_name,))
    
    def _check_rls_enabled(self, table_name: str) -> bool:
        """檢查表是否啟用 RLS"""
        query = """
            SELECT relrowsecurity
            FROM pg_class
            WHERE relname = %s AND relnamespace = 'public'::regnamespace;
        """
        result = self.execute_query(query, (table_name,))
        return result[0]['relrowsecurity'] if result else False
    
    # ========================================================================
    # Indexes
    # ========================================================================
    def export_indexes(self) -> str:
        """導出索引"""
        print("\n🔍 導出 Indexes...")
        
        query = """
            SELECT 
                i.relname AS index_name,
                t.relname AS table_name,
                pg_get_indexdef(i.oid) AS index_definition,
                am.amname AS index_type
            FROM pg_index ix
            JOIN pg_class i ON i.oid = ix.indexrelid
            JOIN pg_class t ON t.oid = ix.indrelid
            JOIN pg_namespace n ON n.oid = t.relnamespace
            JOIN pg_am am ON am.oid = i.relam
            WHERE n.nspname = 'public'
              AND NOT ix.indisprimary
              AND NOT ix.indisunique
              AND i.relname NOT LIKE 'pg_%'
            ORDER BY t.relname, i.relname;
        """
        indexes = self.execute_query(query)
        
        lines = [
            "-- ============================================================================",
            "-- Indexes（索引）",
            f"-- 導出時間：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            "-- ============================================================================",
            ""
        ]
        
        current_table = None
        for idx in indexes:
            if idx['table_name'] != current_table:
                current_table = idx['table_name']
                lines.append(f"-- Table: {current_table}")
            
            lines.append(f"-- Index: {idx['index_name']} ({idx['index_type']})")
            lines.append(f"{idx['index_definition']};")
            lines.append("")
        
        print(f"   找到 {len(indexes)} 個索引")
        return "\n".join(lines)
    
    # ========================================================================
    # Functions
    # ========================================================================
    def export_functions(self) -> str:
        """導出函數（包括 RPC）"""
        print("\n⚡ 導出 Functions...")
        
        query = """
            SELECT 
                p.proname AS function_name,
                n.nspname AS schema_name,
                pg_get_functiondef(p.oid) AS function_definition,
                p.provolatile AS volatility,
                CASE p.prosecdef WHEN true THEN 'SECURITY DEFINER' ELSE 'SECURITY INVOKER' END AS security
            FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE n.nspname = 'public'
              AND p.prokind = 'f'
              AND p.proname NOT LIKE 'pg_%'
              AND p.proname NOT LIKE '_'
            ORDER BY p.proname;
        """
        functions = self.execute_query(query)
        
        lines = [
            "-- ============================================================================",
            "-- Functions（函數）",
            f"-- 導出時間：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            "-- ============================================================================",
            ""
        ]
        
        for func in functions:
            lines.append(f"-- ============================================================================")
            lines.append(f"-- Function: {func['function_name']}")
            lines.append(f"-- Security: {func['security']}")
            lines.append(f"-- ============================================================================")
            lines.append(f"{func['function_definition']}")
            lines.append("")
        
        print(f"   找到 {len(functions)} 個函數")
        return "\n".join(lines)
    
    # ========================================================================
    # Triggers
    # ========================================================================
    def export_triggers(self) -> str:
        """導出觸發器"""
        print("\n🎯 導出 Triggers...")
        
        query = """
            SELECT 
                t.tgname AS trigger_name,
                c.relname AS table_name,
                pg_get_triggerdef(t.oid) AS trigger_definition,
                p.proname AS function_name,
                CASE 
                    WHEN (t.tgtype::int & 2) > 0 THEN 'BEFORE'
                    WHEN (t.tgtype::int & 64) > 0 THEN 'INSTEAD OF'
                    ELSE 'AFTER'
                END AS timing,
                CASE 
                    WHEN (t.tgtype::int & 4) > 0 THEN 'INSERT'
                    WHEN (t.tgtype::int & 8) > 0 THEN 'DELETE'
                    WHEN (t.tgtype::int & 16) > 0 THEN 'UPDATE'
                    ELSE 'UNKNOWN'
                END AS event
            FROM pg_trigger t
            JOIN pg_class c ON t.tgrelid = c.oid
            JOIN pg_namespace n ON c.relnamespace = n.oid
            JOIN pg_proc p ON t.tgfoid = p.oid
            WHERE n.nspname = 'public'
              AND NOT t.tgisinternal
              AND t.tgname NOT LIKE 'RI_%'
            ORDER BY c.relname, t.tgname;
        """
        triggers = self.execute_query(query)
        
        lines = [
            "-- ============================================================================",
            "-- Triggers（觸發器）",
            f"-- 導出時間：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            "-- ============================================================================",
            ""
        ]
        
        current_table = None
        for trig in triggers:
            if trig['table_name'] != current_table:
                current_table = trig['table_name']
                lines.append(f"-- ============================================================================")
                lines.append(f"-- Table: {current_table}")
                lines.append(f"-- ============================================================================")
            
            lines.append(f"-- Trigger: {trig['trigger_name']} ({trig['timing']} {trig['event']})")
            lines.append(f"-- Function: {trig['function_name']}")
            lines.append(f"DROP TRIGGER IF EXISTS {trig['trigger_name']} ON {trig['table_name']};")
            lines.append(f"{trig['trigger_definition']};")
            lines.append("")
        
        print(f"   找到 {len(triggers)} 個觸發器")
        return "\n".join(lines)
    
    # ========================================================================
    # RLS Policies
    # ========================================================================
    def export_rls_policies(self) -> str:
        """導出 RLS 策略"""
        print("\n🔒 導出 RLS Policies...")
        
        query = """
            SELECT 
                pol.polname AS policy_name,
                c.relname AS table_name,
                CASE pol.polcmd
                    WHEN 'r' THEN 'SELECT'
                    WHEN 'a' THEN 'INSERT'
                    WHEN 'w' THEN 'UPDATE'
                    WHEN 'd' THEN 'DELETE'
                    WHEN '*' THEN 'ALL'
                END AS command,
                CASE pol.polpermissive
                    WHEN true THEN 'PERMISSIVE'
                    ELSE 'RESTRICTIVE'
                END AS permissive,
                pg_get_expr(pol.polqual, pol.polrelid) AS using_expression,
                pg_get_expr(pol.polwithcheck, pol.polrelid) AS with_check_expression,
                ARRAY(SELECT rolname FROM pg_roles WHERE oid = ANY(pol.polroles)) AS roles
            FROM pg_policy pol
            JOIN pg_class c ON pol.polrelid = c.oid
            JOIN pg_namespace n ON c.relnamespace = n.oid
            WHERE n.nspname = 'public'
            ORDER BY c.relname, pol.polname;
        """
        policies = self.execute_query(query)
        
        lines = [
            "-- ============================================================================",
            "-- RLS Policies（Row Level Security）",
            f"-- 導出時間：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            "-- ============================================================================",
            ""
        ]
        
        current_table = None
        for pol in policies:
            if pol['table_name'] != current_table:
                current_table = pol['table_name']
                lines.append(f"-- ============================================================================")
                lines.append(f"-- Table: {current_table}")
                lines.append(f"-- ============================================================================")
                lines.append(f"ALTER TABLE {current_table} ENABLE ROW LEVEL SECURITY;")
                lines.append("")
            
            roles = ", ".join(pol['roles']) if pol['roles'] else "public"
            
            lines.append(f"-- Policy: {pol['policy_name']} ({pol['command']})")
            lines.append(f"DROP POLICY IF EXISTS \"{pol['policy_name']}\" ON {pol['table_name']};")
            
            policy_def = f"CREATE POLICY \"{pol['policy_name']}\" ON {pol['table_name']}"
            policy_def += f"\n    AS {pol['permissive']}"
            policy_def += f"\n    FOR {pol['command']}"
            policy_def += f"\n    TO {roles}"
            
            if pol['using_expression']:
                policy_def += f"\n    USING ({pol['using_expression']})"
            if pol['with_check_expression']:
                policy_def += f"\n    WITH CHECK ({pol['with_check_expression']})"
            
            lines.append(f"{policy_def};")
            lines.append("")
        
        print(f"   找到 {len(policies)} 個 RLS 策略")
        return "\n".join(lines)
    
    # ========================================================================
    # Views
    # ========================================================================
    def export_views(self) -> str:
        """導出視圖"""
        print("\n👁️ 導出 Views...")
        
        # 一般視圖
        views_query = """
            SELECT 
                c.relname AS view_name,
                pg_get_viewdef(c.oid, true) AS view_definition,
                'VIEW' AS view_type
            FROM pg_class c
            JOIN pg_namespace n ON c.relnamespace = n.oid
            WHERE c.relkind = 'v'
              AND n.nspname = 'public'
              AND c.relname NOT LIKE 'pg_%'
            ORDER BY c.relname;
        """
        views = self.execute_query(views_query)
        
        # Materialized Views
        matviews_query = """
            SELECT 
                c.relname AS view_name,
                pg_get_viewdef(c.oid, true) AS view_definition,
                'MATERIALIZED VIEW' AS view_type
            FROM pg_class c
            JOIN pg_namespace n ON c.relnamespace = n.oid
            WHERE c.relkind = 'm'
              AND n.nspname = 'public'
            ORDER BY c.relname;
        """
        matviews = self.execute_query(matviews_query)
        
        all_views = views + matviews
        
        lines = [
            "-- ============================================================================",
            "-- Views（視圖）",
            f"-- 導出時間：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            "-- ============================================================================",
            ""
        ]
        
        for view in all_views:
            lines.append(f"-- ============================================================================")
            lines.append(f"-- {view['view_type']}: {view['view_name']}")
            lines.append(f"-- ============================================================================")
            lines.append(f"CREATE OR REPLACE {view['view_type']} {view['view_name']} AS")
            lines.append(f"{view['view_definition']};")
            lines.append("")
        
        print(f"   找到 {len(views)} 個視圖 + {len(matviews)} 個物化視圖")
        return "\n".join(lines)
    
    # ========================================================================
    # Foreign Keys
    # ========================================================================
    def export_foreign_keys(self) -> str:
        """導出外鍵關係"""
        print("\n🔗 導出 Foreign Keys...")
        
        query = """
            SELECT 
                tc.constraint_name,
                tc.table_name,
                kcu.column_name,
                ccu.table_name AS foreign_table_name,
                ccu.column_name AS foreign_column_name,
                rc.update_rule,
                rc.delete_rule
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu
                ON tc.constraint_name = kcu.constraint_name
                AND tc.table_schema = kcu.table_schema
            JOIN information_schema.constraint_column_usage ccu
                ON tc.constraint_name = ccu.constraint_name
                AND tc.table_schema = ccu.table_schema
            JOIN information_schema.referential_constraints rc
                ON tc.constraint_name = rc.constraint_name
            WHERE tc.constraint_type = 'FOREIGN KEY'
              AND tc.table_schema = 'public'
            ORDER BY tc.table_name, tc.constraint_name;
        """
        fks = self.execute_query(query)
        
        lines = [
            "-- ============================================================================",
            "-- Foreign Keys（外鍵關係）",
            f"-- 導出時間：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            "-- ============================================================================",
            ""
        ]
        
        current_table = None
        for fk in fks:
            if fk['table_name'] != current_table:
                current_table = fk['table_name']
                lines.append(f"-- Table: {current_table}")
            
            on_update = f"ON UPDATE {fk['update_rule']}" if fk['update_rule'] != 'NO ACTION' else ""
            on_delete = f"ON DELETE {fk['delete_rule']}" if fk['delete_rule'] != 'NO ACTION' else ""
            
            lines.append(f"ALTER TABLE {fk['table_name']}")
            lines.append(f"    ADD CONSTRAINT {fk['constraint_name']}")
            lines.append(f"    FOREIGN KEY ({fk['column_name']})")
            lines.append(f"    REFERENCES {fk['foreign_table_name']}({fk['foreign_column_name']})")
            if on_update or on_delete:
                lines.append(f"    {on_update} {on_delete}".strip())
            lines.append(";")
            lines.append("")
        
        print(f"   找到 {len(fks)} 個外鍵")
        return "\n".join(lines)
    
    # ========================================================================
    # Generate Report
    # ========================================================================
    def generate_report(self) -> str:
        """生成比對報告"""
        print("\n📝 生成比對報告...")
        
        # 讀取現有 migrations
        existing_migrations = self._read_existing_migrations()
        
        # 分析各類 objects
        tables = self._get_all_tables()
        functions = self._get_all_functions()
        triggers = self._get_all_triggers()
        policies = self._get_all_policies()
        
        lines = [
            "# Database Schema 導出報告",
            "",
            f"**導出時間**：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            "",
            "---",
            "",
            "## 📊 數據庫現況",
            "",
            "| 類型 | 數量 |",
            "|------|------|",
            f"| Tables | {len(tables)} |",
            f"| Functions | {len(functions)} |",
            f"| Triggers | {len(triggers)} |",
            f"| RLS Policies | {len(policies)} |",
            "",
            "---",
            "",
            "## 📁 現有 Migrations 分析",
            "",
            f"共 {len(existing_migrations)} 個檔案",
            "",
        ]
        
        # 分類統計
        fix_migrations = [m for m in existing_migrations if 'fix' in m.lower()]
        feature_migrations = [m for m in existing_migrations if 'fix' not in m.lower()]
        
        lines.extend([
            "### 功能 Migrations",
            "",
        ])
        for m in feature_migrations:
            lines.append(f"- `{m}`")
        
        lines.extend([
            "",
            "### 修復 Migrations（可能可合併）",
            "",
        ])
        for m in fix_migrations:
            lines.append(f"- `{m}`")
        
        lines.extend([
            "",
            "---",
            "",
            "## 🔧 整理建議",
            "",
            "### 可合併的 Migrations",
            "",
        ])
        
        # 找出可合併的組
        merge_groups = self._find_merge_candidates(existing_migrations)
        for group_name, migrations in merge_groups.items():
            if len(migrations) > 1:
                lines.append(f"#### {group_name}")
                for m in migrations:
                    lines.append(f"- `{m}`")
                lines.append("")
        
        lines.extend([
            "",
            "### 建議的整理方案",
            "",
            "1. **保留核心 migrations**：001-007（v1.0-v2.0 核心功能）",
            "2. **合併 fix migrations**：把相同功能的修復合併到原功能檔案",
            "3. **建立 consolidated 資料夾**：放整合後的精簡版本",
            "",
            "---",
            "",
            "## 📋 Tables 清單",
            "",
        ])
        
        for table in sorted(tables):
            lines.append(f"- `{table}`")
        
        lines.extend([
            "",
            "## ⚡ Functions 清單",
            "",
        ])
        
        for func in sorted(functions):
            lines.append(f"- `{func}`")
        
        lines.extend([
            "",
            "## 🎯 Triggers 清單",
            "",
        ])
        
        for trig in sorted(triggers):
            lines.append(f"- `{trig}`")
        
        return "\n".join(lines)
    
    def _read_existing_migrations(self) -> List[str]:
        """讀取現有 migrations 檔案列表"""
        migrations = []
        if os.path.exists(MIGRATIONS_DIR):
            for f in os.listdir(MIGRATIONS_DIR):
                if f.endswith('.sql'):
                    migrations.append(f)
        return sorted(migrations)
    
    def _get_all_tables(self) -> List[str]:
        """取得所有表名"""
        query = """
            SELECT relname FROM pg_class c
            JOIN pg_namespace n ON c.relnamespace = n.oid
            WHERE c.relkind = 'r' AND n.nspname = 'public'
              AND c.relname NOT LIKE 'pg_%';
        """
        result = self.execute_query(query)
        return [r['relname'] for r in result]
    
    def _get_all_functions(self) -> List[str]:
        """取得所有函數名"""
        query = """
            SELECT proname FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE n.nspname = 'public' AND p.prokind = 'f';
        """
        result = self.execute_query(query)
        return [r['proname'] for r in result]
    
    def _get_all_triggers(self) -> List[str]:
        """取得所有觸發器名"""
        query = """
            SELECT t.tgname, c.relname FROM pg_trigger t
            JOIN pg_class c ON t.tgrelid = c.oid
            JOIN pg_namespace n ON c.relnamespace = n.oid
            WHERE n.nspname = 'public' AND NOT t.tgisinternal;
        """
        result = self.execute_query(query)
        return [f"{r['tgname']} ON {r['relname']}" for r in result]
    
    def _get_all_policies(self) -> List[str]:
        """取得所有 RLS 策略"""
        query = """
            SELECT pol.polname, c.relname FROM pg_policy pol
            JOIN pg_class c ON pol.polrelid = c.oid
            JOIN pg_namespace n ON c.relnamespace = n.oid
            WHERE n.nspname = 'public';
        """
        result = self.execute_query(query)
        return [f"{r['polname']} ON {r['relname']}" for r in result]
    
    def _find_merge_candidates(self, migrations: List[str]) -> Dict[str, List[str]]:
        """找出可合併的 migrations"""
        groups = defaultdict(list)
        
        keywords = {
            'pr': 'PR 相關',
            'rls': 'RLS 相關',
            'trigger': '觸發器相關',
            'session': 'Session 相關',
            'appointment': '預約相關',
            'workout': '訓練相關',
            'health': '健康評估相關',
            'coach': '教練相關',
            'tracking': 'Tracking 相關',
        }
        
        for m in migrations:
            m_lower = m.lower()
            for keyword, group_name in keywords.items():
                if keyword in m_lower:
                    groups[group_name].append(m)
                    break
        
        return dict(groups)
    
    # ========================================================================
    # Main Export
    # ========================================================================
    def export_all(self):
        """執行完整導出"""
        os.makedirs(OUTPUT_DIR, exist_ok=True)
        
        try:
            self.connect()
            
            # 導出各類 schema
            exports = [
                ("00_extensions.sql", self.export_extensions),
                ("01_types.sql", self.export_types),
                ("02_tables.sql", self.export_tables),
                ("03_indexes.sql", self.export_indexes),
                ("04_functions.sql", self.export_functions),
                ("05_triggers.sql", self.export_triggers),
                ("06_rls_policies.sql", self.export_rls_policies),
                ("07_views.sql", self.export_views),
                ("08_foreign_keys.sql", self.export_foreign_keys),
            ]
            
            for filename, export_func in exports:
                content = export_func()
                filepath = os.path.join(OUTPUT_DIR, filename)
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"   ✅ 已寫入 {filename}")
            
            # 生成報告
            report = self.generate_report()
            report_path = os.path.join(OUTPUT_DIR, "schema_report.md")
            with open(report_path, 'w', encoding='utf-8') as f:
                f.write(report)
            print(f"   ✅ 已寫入 schema_report.md")
            
        finally:
            self.disconnect()


def main():
    print("=" * 70)
    print("🗄️  Database Schema 完整導出工具")
    print(f"   時間: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 70)
    
    # 取得連接字串
    database_url = os.getenv("DATABASE_URL")
    
    if not database_url:
        print("\n❌ 請設定 DATABASE_URL 環境變數")
        print("\n   方法 1: 在 .env 檔案中設定")
        print("   DATABASE_URL=postgresql://postgres:xxx@db.xxx.supabase.co:5432/postgres")
        print("\n   方法 2: 直接設定環境變數")
        print("   Windows: set DATABASE_URL=postgresql://...")
        print("   Linux/Mac: export DATABASE_URL=postgresql://...")
        print("\n   連接字串取得方式:")
        print("   1. 登入 Supabase Dashboard")
        print("   2. Settings → Database")
        print("   3. 找到 'Connection string' → 'URI'")
        print("   4. 複製並替換 [YOUR-PASSWORD] 為實際密碼")
        sys.exit(1)
    
    print(f"\n🔗 連接字串: {database_url[:50]}...")
    print(f"📁 輸出目錄: {OUTPUT_DIR}")
    
    try:
        exporter = DatabaseSchemaExporter(database_url)
        exporter.export_all()
        
        print("\n" + "=" * 70)
        print("✅ 導出完成！")
        print("=" * 70)
        print(f"\n📁 輸出檔案位於: {OUTPUT_DIR}")
        print("\n檔案清單:")
        for f in sorted(os.listdir(OUTPUT_DIR)):
            filepath = os.path.join(OUTPUT_DIR, f)
            size = os.path.getsize(filepath)
            print(f"   - {f} ({size:,} bytes)")
        
    except Exception as e:
        print(f"\n❌ 導出失敗: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
