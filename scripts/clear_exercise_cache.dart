#!/usr/bin/env dart
// -*- coding: utf-8 -*-
/// 
/// 清除運動庫快取腳本
/// 
/// 在更新 Firestore 資料後執行，確保應用使用最新資料
/// 

import 'dart:io';
import 'package:hive/Hive.dart';
import 'package:path/path.dart' as path;

void main() async {
  print('=' * 60);
  print('清除運動庫快取');
  print('=' * 60);
  
  try {
    // 獲取快取目錄
    // 注意：這個路徑可能需要根據實際情況調整
    final homePath = Platform.environment['HOME'] ?? 
                     Platform.environment['USERPROFILE'] ?? 
                     '.';
    
    // Android: /data/data/com.example.strengthwise/app_flutter
    // iOS: Library/Caches
    final cachePaths = [
      path.join(homePath, '.cache', 'strengthwise'),
      path.join(homePath, 'AppData', 'Local', 'strengthwise'),
    ];
    
    print('\n正在清除快取...');
    
    bool foundCache = false;
    for (final cachePath in cachePaths) {
      final dir = Directory(cachePath);
      if (await dir.exists()) {
        print('  找到快取目錄: $cachePath');
        
        // 刪除 Hive 快取文件
        final hiveFiles = [
          'exercise_categories.hive',
          'exercise_categories.lock',
          'exercises_cache.hive',
          'exercises_cache.lock',
        ];
        
        for (final fileName in hiveFiles) {
          final file = File(path.join(cachePath, fileName));
          if (await file.exists()) {
            await file.delete();
            print('  ✓ 已刪除: $fileName');
            foundCache = true;
          }
        }
      }
    }
    
    if (!foundCache) {
      print('\n  ℹ️ 未找到快取文件（可能已被清除或路徑不同）');
      print('  \n請在應用中手動清除快取：');
      print('  設定 → 清除快取 → 重新載入資料');
    } else {
      print('\n✓ 快取清除完成！');
    }
    
  } catch (e) {
    print('\n❌ 清除快取時發生錯誤: $e');
    print('\n請手動清除快取：');
    print('  1. 解除安裝應用');
    print('  2. 重新安裝應用');
    print('  或在應用設定中清除資料');
  }
  
  print('\n' + '=' * 60);
  print('完成');
  print('=' * 60);
}

