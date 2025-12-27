#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Download Complete Supabase Database

This script will:
1. Connect to Supabase
2. Download all table data (9 tables)
3. Save as JSON format
4. Generate database structure report

Usage:
    python scripts/download_complete_database.py

Output:
    - database_export/
        |- users.json                (User data)
        |- exercises.json            (System exercises - 794 records)
        |- custom_exercises.json     (User custom exercises)
        |- workout_plans.json        (Workout plans and records)
        |- workout_templates.json    (Workout templates)
        |- body_data.json            (Body measurements)
        |- notes.json                (User notes)
        |- body_parts.json           (Metadata: body parts)
        |- exercise_types.json       (Metadata: exercise types)
    
    - docs/DATABASE_SUPABASE.md      (Updated with latest statistics)
"""

import sys
import os
import json
from datetime import datetime
from typing import List, Dict, Any
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
    print(f"Loaded environment variables: {ENV_FILE}")
else:
    load_dotenv()

# Supabase configuration
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("[ERROR] Please set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables")
    print("        Make sure .env file exists and contains correct values")
    sys.exit(1)

# Initialize Supabase Client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def ensure_export_dir():
    """Ensure export directory exists"""
    os.makedirs("database_export", exist_ok=True)

def download_table(table_name: str) -> list:
    """Download all data from specified table"""
    print(f"Downloading {table_name}...")
    
    try:
        response = supabase.table(table_name).select("*").execute()
        data = response.data
        print(f"  {table_name}: {len(data)} records")
        return data
    except Exception as e:
        print(f"  Failed to download {table_name}: {e}")
        return []

def save_json(data: any, filename: str):
    """Save data as JSON file"""
    filepath = os.path.join("database_export", filename)
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2, default=str)
    print(f"  Saved: {filepath}")

def download_all_tables() -> Dict[str, List]:
    """Download all tables"""
    print("\nDownloading all tables...")
    print("-" * 60)
    
    # 核心表格（6 個）
    core_tables = [
        "users",
        "exercises",
        "custom_exercises",
        "workout_plans",
        "workout_templates",
        "body_data",
        "notes"
    ]
    
    # 元數據表格（3 個）
    metadata_tables = [
        "body_parts",
        "exercise_types"
    ]
    
    # 合併所有表格（9 個）
    all_tables = core_tables + metadata_tables
    all_data = {}
    
    print(f"Total tables to download: {len(all_tables)}")
    print(f"Core tables: {', '.join(core_tables)}")
    print(f"Metadata tables: {', '.join(metadata_tables)}")
    print("-" * 60)
    
    for table_name in all_tables:
        data = download_table(table_name)
        all_data[table_name] = data
        
        # Save complete data
        save_json(data, f"{table_name}.json")
    
    return all_data

def generate_structure_doc(all_data: Dict[str, List]):
    """Generate complete database structure documentation"""
    print("\nGenerating structure documentation...")
    
    doc = []
    doc.append("# StrengthWise Database Structure")
    doc.append(f"\nExported at: {datetime.now().isoformat()}\n")
    doc.append("=" * 80)
    
    for table_name, data in all_data.items():
        doc.append(f"\n## Table: {table_name}")
        doc.append(f"\n**Record Count**: {len(data)}")
        
        if data:
            # Get columns
            sample = data[0]
            doc.append(f"\n### Columns ({len(sample.keys())})")
            doc.append("\n| Column | Type | Sample Value |")
            doc.append("|--------|------|--------------|")
            
            for key, value in sample.items():
                value_type = type(value).__name__
                sample_value = str(value)[:50] + "..." if len(str(value)) > 50 else str(value)
                doc.append(f"| {key} | {value_type} | {sample_value} |")
            
            # Statistics
            doc.append(f"\n### Statistics")
            doc.append(f"- Total records: {len(data)}")
            
            # Add table-specific statistics
            if table_name == "exercises":
                training_types = {}
                for item in data:
                    t_type = item.get('training_type', 'Unknown')
                    training_types[t_type] = training_types.get(t_type, 0) + 1
                
                doc.append("\n**Training Types:**")
                for t_type, count in sorted(training_types.items(), key=lambda x: x[1], reverse=True):
                    doc.append(f"- {t_type}: {count}")
            
            elif table_name == "custom_exercises":
                body_parts = {}
                for item in data:
                    bp = item.get('body_part', 'Unknown')
                    body_parts[bp] = body_parts.get(bp, 0) + 1
                
                doc.append("\n**Body Parts Distribution:**")
                for bp, count in sorted(body_parts.items(), key=lambda x: x[1], reverse=True):
                    doc.append(f"- {bp}: {count}")
            
            elif table_name == "workout_plans":
                completed = sum(1 for item in data if item.get('completed'))
                pending = len(data) - completed
                doc.append(f"- Completed: {completed}")
                doc.append(f"- Pending: {pending}")
                
                # Calculate total volume
                total_volume = sum(item.get('total_volume', 0) for item in data if item.get('completed'))
                doc.append(f"- Total training volume: {total_volume:.1f} kg")
            
            elif table_name == "workout_templates":
                doc.append(f"- User templates: {len(data)}")
            
            elif table_name == "body_data":
                if data:
                    weights = [item.get('weight') for item in data if item.get('weight')]
                    if weights:
                        doc.append(f"- Weight range: {min(weights):.1f} - {max(weights):.1f} kg")
                        doc.append(f"- Average weight: {sum(weights)/len(weights):.1f} kg")
                    
                    body_fats = [item.get('body_fat') for item in data if item.get('body_fat')]
                    if body_fats:
                        doc.append(f"- Body fat range: {min(body_fats):.1f}% - {max(body_fats):.1f}%")
            
            elif table_name == "body_parts":
                names = [item.get('name', 'Unknown') for item in data]
                doc.append(f"\n**Body Parts:**")
                for name in sorted(names):
                    doc.append(f"- {name}")
            
            elif table_name == "exercise_types":
                names = [item.get('name', 'Unknown') for item in data]
                doc.append(f"\n**Exercise Types:**")
                for name in sorted(names):
                    doc.append(f"- {name}")
        
        doc.append("\n" + "-" * 80)
    
    # Save documentation
    filepath = os.path.join("database_export", "database_structure.md")
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write("\n".join(doc))
    
    print(f"  Saved: {filepath}")

def main():
    """Main function"""
    print("=" * 60)
    print("StrengthWise - Complete Database Download Tool")
    print("=" * 60)
    print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    try:
        print(f"Connected to Supabase: {SUPABASE_URL}\n")
        
        # Ensure export directory exists
        ensure_export_dir()
        
        # Download all tables
        all_data = download_all_tables()
        
        # Generate structure documentation
        generate_structure_doc(all_data)
        
        # Generate summary
        print("\n" + "=" * 60)
        print("Download Summary")
        print("=" * 60)
        for table_name, data in all_data.items():
            print(f"  {table_name}: {len(data)} records")
        
        print("\nAll data downloaded successfully!")
        print("Output directory: database_export/")
        print("\nNext steps:")
        print("  1. Review database_structure.md for complete structure")
        print("  2. Check individual JSON files for data details")
        
    except Exception as e:
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())

