#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Download Supabase Database Complete Data

This script will:
1. Connect to Supabase
2. Download all table data
3. Save as JSON format
4. Generate database structure report

Usage:
    python scripts/download_database.py

Output:
    - database_export/
        |- database_structure.json  (Database structure)
        |- users.json              (User data)
        |- exercises.json          (Exercise data)
        |- equipments.json         (Equipment data)
        |- joint_types.json        (Joint type data)
        |- workout_plans.json      (Workout plan data)
        |- body_data.json          (Body data)
        |- notes.json              (Notes data)
        |- favorite_exercises.json (Favorite exercises)
"""

import os
import json
from datetime import datetime
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def get_supabase_client() -> Client:
    """Get Supabase client"""
    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_ANON_KEY")
    
    if not url or not key:
        raise ValueError("Please set SUPABASE_URL and SUPABASE_ANON_KEY environment variables")
    
    return create_client(url, key)

def ensure_export_dir():
    """Ensure export directory exists"""
    os.makedirs("database_export", exist_ok=True)

def download_table(supabase: Client, table_name: str) -> list:
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

def analyze_structure(supabase: Client) -> dict:
    """Analyze database structure"""
    print("\nAnalyzing database structure...")
    print("-" * 60)
    
    tables = [
        "users",
        "exercises",
        "equipments",
        "joint_types",
        "workout_plans",
        "body_data",
        "notes",
        "favorite_exercises"
    ]
    
    structure = {
        "exported_at": datetime.now().isoformat(),
        "tables": {}
    }
    
    for table_name in tables:
        data = download_table(supabase, table_name)
        
        # Save complete data
        save_json(data, f"{table_name}.json")
        
        # Analyze structure
        if data:
            sample = data[0]
            structure["tables"][table_name] = {
                "count": len(data),
                "columns": list(sample.keys()),
                "sample": sample
            }
    
    return structure

def main():
    """Main function"""
    print("=" * 60)
    print("Supabase Database Download Tool")
    print("=" * 60)
    
    try:
        # Connect
        supabase = get_supabase_client()
        print("Connected to Supabase\n")
        
        # Ensure export directory exists
        ensure_export_dir()
        
        # Analyze and download database
        structure = analyze_structure(supabase)
        
        # Save structure report
        save_json(structure, "database_structure.json")
        
        # Generate summary
        print("\n" + "=" * 60)
        print("Download Summary")
        print("=" * 60)
        for table_name, info in structure["tables"].items():
            print(f"  {table_name}: {info['count']} records")
        
        print("\nAll data downloaded successfully!")
        print("Output directory: database_export/")
        
    except Exception as e:
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
