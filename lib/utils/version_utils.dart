/// 版本比較工具類
///
/// 支援語意化版本（Semantic Versioning）比較
/// 格式：major.minor.patch（例如 1.2.3）
class VersionUtils {
  VersionUtils._();

  /// 比較兩個版本字串
  ///
  /// 返回值：
  /// - 負數：[a] < [b]
  /// - 0：[a] == [b]
  /// - 正數：[a] > [b]
  static int compare(String a, String b) {
    final partsA = _parseVersion(a);
    final partsB = _parseVersion(b);

    for (int i = 0; i < 3; i++) {
      if (partsA[i] != partsB[i]) {
        return partsA[i] - partsB[i];
      }
    }
    return 0;
  }

  /// [current] 是否低於 [latestVersion]（有可用更新）
  static bool hasUpdate(String current, String latestVersion) {
    return compare(current, latestVersion) < 0;
  }

  /// 解析版本字串為 [major, minor, patch]
  static List<int> _parseVersion(String version) {
    // 移除可能的 'v' 前綴和 build number（+16）
    final cleaned = version.replaceAll(RegExp(r'^v'), '').split('+').first;
    final parts = cleaned.split('.');

    return [
      parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0,
      parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0,
    ];
  }
}
