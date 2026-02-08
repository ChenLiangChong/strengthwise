import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 動作庫偏好設定服務
///
/// 負責瀏覽模式和器材偏好的持久化存儲與讀取。
/// 使用 SharedPreferences，遵循 ThemeService 模式。
class ExercisePreferencesService {
  static const String _browseModeKey = 'exercise_browse_mode';
  static const String _myEquipmentKey = 'exercise_my_equipment';

  /// 讀取瀏覽模式偏好
  ///
  /// 返回 'anatomy' 或 'pattern'，預設 'pattern'
  Future<String> getBrowseMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_browseModeKey) ?? 'pattern';
    } catch (e) {
      debugPrint('ExercisePreferencesService: 讀取瀏覽模式失敗 - $e');
      return 'pattern';
    }
  }

  /// 保存瀏覽模式偏好
  ///
  /// 參數：
  /// - mode: 'anatomy' 或 'pattern'
  Future<void> setBrowseMode(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_browseModeKey, mode);
      debugPrint('ExercisePreferencesService: 瀏覽模式已保存 - $mode');
    } catch (e) {
      debugPrint('ExercisePreferencesService: 保存瀏覽模式失敗 - $e');
    }
  }

  /// 讀取使用者的健身房器材
  ///
  /// 返回器材 ID 集合，預設空集合
  Future<Set<String>> getMyEquipment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_myEquipmentKey);
      if (jsonStr == null) return {};

      final List<dynamic> list = json.decode(jsonStr) as List<dynamic>;
      return list.cast<String>().toSet();
    } catch (e) {
      debugPrint('ExercisePreferencesService: 讀取器材偏好失敗 - $e');
      return {};
    }
  }

  /// 保存使用者的健身房器材
  ///
  /// 參數：
  /// - equipment: 器材 ID 集合
  Future<void> setMyEquipment(Set<String> equipment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(equipment.toList());
      await prefs.setString(_myEquipmentKey, jsonStr);
      debugPrint(
        'ExercisePreferencesService: 器材偏好已保存 - ${equipment.length} 項',
      );
    } catch (e) {
      debugPrint('ExercisePreferencesService: 保存器材偏好失敗 - $e');
    }
  }
}
