/// 標記樣式配置
///
/// 定義標記點的視覺樣式
class MarkerStyle {
  /// 標記點大小
  final double size;

  /// 標記點間距
  final double spacing;

  /// 標記點位置（距離底部）
  final double bottomOffset;

  const MarkerStyle({
    this.size = 6.0,
    this.spacing = 2.0,
    this.bottomOffset = 4.0,
  });

  /// 預設樣式
  static const MarkerStyle defaultStyle = MarkerStyle();

  /// 小尺寸樣式
  static const MarkerStyle small = MarkerStyle(
    size: 4.0,
    spacing: 1.5,
    bottomOffset: 3.0,
  );

  /// 大尺寸樣式
  static const MarkerStyle large = MarkerStyle(
    size: 8.0,
    spacing: 3.0,
    bottomOffset: 5.0,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarkerStyle &&
        other.size == size &&
        other.spacing == spacing &&
        other.bottomOffset == bottomOffset;
  }

  @override
  int get hashCode => Object.hash(size, spacing, bottomOffset);

  @override
  String toString() =>
      'MarkerStyle(size: $size, spacing: $spacing, bottomOffset: $bottomOffset)';
}

