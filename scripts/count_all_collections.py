#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""快速統計所有集合的文檔數量"""

import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

import os
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = 'strengthwise-service-account.json'

from google.cloud import firestore

db = firestore.Client(project='strengthwise-91f02')

collections = [
    'bodyParts',
    'customExercises', 
    'equipments',
    'exercise',
    'exerciseTypes',
    'jointTypes',
    'users',
    'workoutPlans',
    'workoutTemplates'
]

print("=" * 60)
print("完整的 Firestore 集合清單")
print("=" * 60)

total_docs = 0
for collection_name in collections:
    try:
        docs = list(db.collection(collection_name).limit(1000).stream())
        count = len(docs)
        total_docs += count
        status = "[OK]" if count > 0 else "[EMPTY]"
        print(f"{status} {collection_name:20s} : {count:4d} docs")
    except Exception as e:
        print(f"[ERROR] {collection_name:20s} : {e}")

print("=" * 60)
print(f"Total: {total_docs} documents")
print("=" * 60)

