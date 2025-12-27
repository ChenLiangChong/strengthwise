import '../../models/body_data_record.dart';

/// 身體數據操作助手
class BodyDataOperationHelper {
  /// 創建身體數據記錄
  /// 
  /// 如果提供了身高，會自動計算 BMI
  static BodyDataRecord createRecord({
    required String userId,
    required DateTime recordDate,
    required double weight,
    double? bodyFat,
    double? muscleMass,
    double? heightCm,
    String? notes,
  }) {
    // 計算 BMI（如果提供了身高）
    double? bmi;
    if (heightCm != null) {
      bmi = BodyDataRecord.calculateBMI(weight, heightCm);
    }

    return BodyDataRecord(
      id: '', // Service 層會生成
      userId: userId,
      recordDate: recordDate,
      weight: weight,
      bodyFat: bodyFat,
      muscleMass: muscleMass,
      bmi: bmi,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  /// 更新身體數據記錄（重新計算 BMI）
  static BodyDataRecord updateRecord(BodyDataRecord record, {double? heightCm}) {
    if (heightCm == null) {
      return record;
    }
    
    final bmi = BodyDataRecord.calculateBMI(record.weight, heightCm);
    return record.copyWith(bmi: bmi);
  }
}

