# Flutter UI 組件規範

<critical>
1. 禁止硬編碼顏色，必須使用 `Theme.of(context).colorScheme`
2. 禁止硬編碼文字樣式，必須使用 `Theme.of(context).textTheme`
3. 所有尺寸必須是 8 的倍數（8 點網格）
4. 最小觸控目標 48dp
5. 禁止使用 Helper Method 提取 UI，必須使用獨立 Widget
</critical>

## ✅ 正確做法

```dart
// 顏色
color: Theme.of(context).colorScheme.primary

// 文字樣式
style: Theme.of(context).textTheme.titleLarge

// 8 點網格
padding: const EdgeInsets.all(16)
SizedBox(height: 48)  // 觸控目標

// 獨立 Widget（可緩存）
class _WorkoutHeader extends StatelessWidget {}

// const 優化
const SizedBox(height: 16),
```

## ❌ 禁止做法

```dart
// 硬編碼顏色
color: Color(0xFF2563EB)
color: Colors.blue

// 硬編碼樣式
style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)

// 非 8 倍數
padding: EdgeInsets.all(13)

// Helper Method（無法緩存）
Widget _buildHeader() => ...
```

## 🎴 標準卡片

```dart
Card(
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(color: Theme.of(context).colorScheme.outline),
  ),
  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
)
```

詳見：`@docs/UI_DEVELOPER_GUIDE.md`
