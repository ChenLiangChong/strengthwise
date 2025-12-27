import '../../../models/body_data_record.dart';

/// 身體數據計算模組
/// 
/// 負責計算身體數據的統計指標
class BodyDataCalculator {
  final void Function(String) _logDebug;
  final void Function(String, [Object?]) _logError;

  BodyDataCalculator({
    required void Function(String) logDebug,
    required void Function(String, [Object?]) logError,
  })  : _logDebug = logDebug,
        _logError = logError;

  /// 計算平均體重
  Future<double?> calculateAverageWeight(List<BodyDataRecord> records) async {
    try {
      if (records.isEmpty) {
        return null;
      }

      final totalWeight = records.fold<double>(
        0,
        (sum, record) => sum + record.weight,
      );

      final average = totalWeight / records.length;
      _logDebug('✅ 平均體重: ${average.toStringAsFixed(1)} kg');
      return average;
    } catch (e) {
      _logError('計算平均體重失敗', e);
      return null;
    }
  }
}

