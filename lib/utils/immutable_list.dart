/// 不可變列表工具類
///
/// 強制狀態管理最佳實踐：每次修改都返回新實例
/// 避免直接 .add() 修改列表導致 ChangeNotifier 無法正確通知 UI
///
/// 使用範例：
/// ```dart
/// class MyController extends ChangeNotifier {
///   ImmutableList<Item> _items = ImmutableList();
///
///   List<Item> get items => _items.toList();
///
///   void addItem(Item item) {
///     _items = _items.add(item);  // 必須賦值，自然會想到要 notifyListeners
///     notifyListeners();
///   }
/// }
/// ```
class ImmutableList<T> {
  final List<T> _items;

  /// 創建不可變列表
  ///
  /// [items] 初始項目，會被複製一份（不會持有原列表引用）
  ImmutableList([List<T>? items]) : _items = List.unmodifiable(items ?? []);

  // ==================== 讀取操作 ====================

  /// 列表長度
  int get length => _items.length;

  /// 是否為空
  bool get isEmpty => _items.isEmpty;

  /// 是否非空
  bool get isNotEmpty => _items.isNotEmpty;

  /// 取得指定索引的項目
  T operator [](int index) => _items[index];

  /// 取得第一個項目（列表為空時拋出異常）
  T get first => _items.first;

  /// 取得最後一個項目（列表為空時拋出異常）
  T get last => _items.last;

  /// 轉換為普通列表（返回副本）
  List<T> toList() => List.from(_items);

  /// 迭代所有項目
  Iterable<T> get iterable => _items;

  /// 檢查是否包含指定項目
  bool contains(T item) => _items.contains(item);

  /// 取得指定項目的索引（不存在返回 -1）
  int indexOf(T item) => _items.indexOf(item);

  /// 遍歷列表
  void forEach(void Function(T) action) => _items.forEach(action);

  /// 映射轉換
  ImmutableList<R> map<R>(R Function(T) convert) =>
      ImmutableList(_items.map(convert).toList());

  /// 過濾
  ImmutableList<T> where(bool Function(T) test) =>
      ImmutableList(_items.where(test).toList());

  /// 檢查是否所有項目都符合條件
  bool every(bool Function(T) test) => _items.every(test);

  /// 檢查是否有任何項目符合條件
  bool any(bool Function(T) test) => _items.any(test);

  // ==================== 修改操作（返回新實例） ====================

  /// 新增項目到尾部
  ///
  /// 返回包含新項目的新列表，原列表不變
  ImmutableList<T> add(T item) => ImmutableList([..._items, item]);

  /// 新增多個項目到尾部
  ImmutableList<T> addAll(Iterable<T> items) =>
      ImmutableList([..._items, ...items]);

  /// 在指定位置插入項目
  ImmutableList<T> insert(int index, T item) => ImmutableList([
        ..._items.sublist(0, index),
        item,
        ..._items.sublist(index),
      ]);

  /// 移除指定索引的項目
  ///
  /// 返回移除後的新列表，原列表不變
  ImmutableList<T> removeAt(int index) {
    if (index < 0 || index >= _items.length) return this;
    return ImmutableList([
      ..._items.sublist(0, index),
      ..._items.sublist(index + 1),
    ]);
  }

  /// 移除最後一個項目
  ///
  /// 返回移除後的新列表，原列表不變
  /// 如果列表為空，返回原列表
  ImmutableList<T> removeLast() {
    if (_items.isEmpty) return this;
    return ImmutableList(_items.sublist(0, _items.length - 1));
  }

  /// 移除符合條件的第一個項目
  ImmutableList<T> removeWhere(bool Function(T) test) {
    final index = _items.indexWhere(test);
    if (index == -1) return this;
    return removeAt(index);
  }

  /// 更新指定索引的項目
  ///
  /// 返回更新後的新列表，原列表不變
  ImmutableList<T> updateAt(int index, T item) {
    if (index < 0 || index >= _items.length) return this;
    return ImmutableList([
      ..._items.sublist(0, index),
      item,
      ..._items.sublist(index + 1),
    ]);
  }

  /// 使用函數更新指定索引的項目
  ImmutableList<T> updateWhere(int index, T Function(T) update) {
    if (index < 0 || index >= _items.length) return this;
    return updateAt(index, update(_items[index]));
  }

  /// 清空列表
  ///
  /// 返回空的新列表
  ImmutableList<T> clear() => ImmutableList<T>();

  /// 反轉列表
  ImmutableList<T> get reversed => ImmutableList(_items.reversed.toList());

  // ==================== 其他 ====================

  @override
  String toString() => 'ImmutableList($_items)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ImmutableList<T>) return false;
    if (_items.length != other._items.length) return false;
    for (var i = 0; i < _items.length; i++) {
      if (_items[i] != other._items[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_items);
}
