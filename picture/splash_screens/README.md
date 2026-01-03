# Splash Screen 資產清單

## 📁 資料夾結構

```
splash_screens/
├── master/          # 原始母版（3200x3200）
├── ios/             # iOS 設備專用
└── android/         # Android 設備專用
```

## 📱 iOS 設備尺寸列表

### iPhone (Portrait 直屏)
- **iPhone_ProMax**: 1320 × 2868 px (iPhone 16/15/14 Pro Max)
- **iPhone_Pro**: 1206 × 2622 px (iPhone 16/15/14 Pro)
- **iPhone_Plus**: 1290 × 2796 px (iPhone 16/15/14 Plus)
- **iPhone_Standard**: 1170 × 2532 px (iPhone 12/13/14/15/16)
- **iPhone_SE**: 750 × 1334 px (iPhone SE 3rd gen)

### iPad (Portrait 直屏)
- **iPad_Pro_13_Portrait**: 2064 × 2752 px (iPad Pro 13" M4)
- **iPad_Pro_11_Portrait**: 1668 × 2420 px (iPad Pro 11" / Air)
- **iPad_Mini_Portrait**: 1488 × 2266 px (iPad mini 6)

### iPad (Landscape 橫屏)
- **iPad_Pro_13_Landscape**: 2752 × 2064 px (iPad Pro 13" M4)
- **iPad_Pro_11_Landscape**: 2420 × 1668 px (iPad Pro 11" / Air)
- **iPad_Mini_Landscape**: 2266 × 1488 px (iPad mini 6)

## 🤖 Android 密度尺寸列表

### Portrait (直屏)
- **xxxhdpi**: 1440 × 3200 px (4x - 頂級旗艦)
- **xxhdpi**: 1080 × 2400 px (3x - 主流旗艦)
- **xhdpi**: 720 × 1600 px (2x - 中階機型)
- **hdpi**: 540 × 1200 px (1.5x - 入門機型)
- **mdpi**: 360 × 800 px (1x - 開發基準)

### Landscape (橫屏 - 平板)
- **land_xxxhdpi**: 3200 × 1440 px (平板橫屏)

## 🎯 使用指南

### iOS 整合
1. 將 `ios/` 資料夾中的圖片複製到 Xcode 專案的 `Assets.xcassets/LaunchImage.launchimage/`
2. 在 `Contents.json` 中設定對應的設備映射

### Android 整合
1. 將 `android/` 資料夾中的圖片放入對應的 drawable 資料夾：
   - `splash_xxxhdpi_*.png` → `drawable-xxxhdpi/`
   - `splash_xxhdpi_*.png` → `drawable-xxhdpi/`
   - `splash_xhdpi_*.png` → `drawable-xhdpi/`
   - `splash_hdpi_*.png` → `drawable-hdpi/`
   - `splash_mdpi_*.png` → `drawable-mdpi/`
   - `splash_land_xxxhdpi_*.png` → `drawable-land-xxxhdpi/`

2. 在 `styles.xml` 中設定 Splash Screen 主題

## 📝 技術細節

- **母版尺寸**: 3200 × 3200 px（覆蓋所有極端比例）
- **裁剪方式**: 中心裁剪（確保 Logo 始終居中）
- **重採樣演算法**: LANCZOS（最高質量）
- **輸出格式**: PNG (質量 95%, 優化開啟)
- **長寬比策略**: 根據目標設備動態裁剪，避免拉伸變形

## 🔍 品質保證

✅ 所有圖片均保持霓虹 Logo 在視覺中心
✅ 科技感網格背景完整保留
✅ 發光效果與漸層不失真
✅ 覆蓋 2025-2026 年所有主流設備

---

**生成工具**: generate_splash_screens.py
**生成日期**: 2026-01-02
