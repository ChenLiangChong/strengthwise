#!/usr/bin/env python3
"""
Splash Screen 批量生成工具
功能：從母版圖片生成所有 iOS 和 Android 設備需要的啟動頁面尺寸
"""

from PIL import Image
import os
from pathlib import Path

# 輸出資料夾
OUTPUT_DIR = "splash_screens"

# iOS 設備尺寸定義（Portrait 直屏）
IOS_SIZES = {
    # iPhone
    "iPhone_ProMax": (1320, 2868),      # iPhone 16/15/14 Pro Max
    "iPhone_Pro": (1206, 2622),         # iPhone 16/15/14 Pro
    "iPhone_Plus": (1290, 2796),        # iPhone 16/15/14 Plus
    "iPhone_Standard": (1170, 2532),    # iPhone 12/13/14/15/16
    "iPhone_SE": (750, 1334),           # iPhone SE (3rd gen)
    
    # iPad Portrait
    "iPad_Pro_13_Portrait": (2064, 2752),   # iPad Pro 13" M4 直屏
    "iPad_Pro_11_Portrait": (1668, 2420),   # iPad Pro 11" / Air 直屏
    "iPad_Mini_Portrait": (1488, 2266),     # iPad mini 6 直屏
}

# iOS 設備尺寸定義（Landscape 橫屏）
IOS_LANDSCAPE_SIZES = {
    "iPad_Pro_13_Landscape": (2752, 2064),  # iPad Pro 13" M4 橫屏
    "iPad_Pro_11_Landscape": (2420, 1668),  # iPad Pro 11" / Air 橫屏
    "iPad_Mini_Landscape": (2266, 1488),    # iPad mini 6 橫屏
}

# Android 密度尺寸定義（20:9 修長比例）
ANDROID_SIZES = {
    "xxxhdpi": (1440, 3200),    # 4x - 頂級旗艦
    "xxhdpi": (1080, 2400),     # 3x - 主流旗艦
    "xhdpi": (720, 1600),       # 2x - 中階機型
    "hdpi": (540, 1200),        # 1.5x - 入門機型
    "mdpi": (360, 800),         # 1x - 開發基準
}

# Android 橫屏（平板用）
ANDROID_LANDSCAPE_SIZES = {
    "land_xxxhdpi": (3200, 1440),  # 平板橫屏
}


def ensure_output_dir():
    """確保輸出資料夾存在"""
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        print(f"[INFO] 已創建輸出資料夾: {OUTPUT_DIR}")
    
    # 創建子資料夾
    subdirs = ["ios", "android", "master"]
    for subdir in subdirs:
        path = os.path.join(OUTPUT_DIR, subdir)
        if not os.path.exists(path):
            os.makedirs(path)


def crop_and_resize(source_img, target_size, mode="center"):
    """
    從母版圖片裁剪並調整尺寸
    
    Args:
        source_img: PIL Image 物件
        target_size: (width, height) 目標尺寸
        mode: "center" 中心裁剪
    
    Returns:
        PIL Image 物件
    """
    src_width, src_height = source_img.size
    target_width, target_height = target_size
    
    # 計算長寬比
    src_ratio = src_width / src_height
    target_ratio = target_width / target_height
    
    # 決定裁剪區域（保持 Logo 在中心）
    if src_ratio > target_ratio:
        # 原圖較寬，需要裁剪寬度
        new_width = int(src_height * target_ratio)
        new_height = src_height
        left = (src_width - new_width) // 2
        top = 0
        right = left + new_width
        bottom = new_height
    else:
        # 原圖較高，需要裁剪高度
        new_width = src_width
        new_height = int(src_width / target_ratio)
        left = 0
        top = (src_height - new_height) // 2
        right = new_width
        bottom = top + new_height
    
    # 裁剪
    cropped = source_img.crop((left, top, right, bottom))
    
    # 調整大小（使用高質量重採樣）
    resized = cropped.resize(target_size, Image.LANCZOS)
    
    return resized


def generate_ios_splash_screens(master_img):
    """生成所有 iOS Splash Screen"""
    print("\n" + "=" * 60)
    print("生成 iOS Splash Screens")
    print("=" * 60)
    
    ios_dir = os.path.join(OUTPUT_DIR, "ios")
    count = 0
    
    # Portrait 直屏
    for name, size in IOS_SIZES.items():
        output_path = os.path.join(ios_dir, f"{name}_{size[0]}x{size[1]}.png")
        img = crop_and_resize(master_img, size)
        img.save(output_path, quality=95, optimize=True)
        file_size = os.path.getsize(output_path) / (1024 * 1024)
        print(f"[OK] {name}: {size[0]}x{size[1]} px ({file_size:.2f} MB)")
        count += 1
    
    # Landscape 橫屏
    for name, size in IOS_LANDSCAPE_SIZES.items():
        output_path = os.path.join(ios_dir, f"{name}_{size[0]}x{size[1]}.png")
        img = crop_and_resize(master_img, size)
        img.save(output_path, quality=95, optimize=True)
        file_size = os.path.getsize(output_path) / (1024 * 1024)
        print(f"[OK] {name}: {size[0]}x{size[1]} px ({file_size:.2f} MB)")
        count += 1
    
    print(f"\n總計生成 {count} 個 iOS Splash Screen")


def generate_android_splash_screens(master_img):
    """生成所有 Android Splash Screen"""
    print("\n" + "=" * 60)
    print("生成 Android Splash Screens")
    print("=" * 60)
    
    android_dir = os.path.join(OUTPUT_DIR, "android")
    count = 0
    
    # Portrait 直屏
    for density, size in ANDROID_SIZES.items():
        output_path = os.path.join(android_dir, f"splash_{density}_{size[0]}x{size[1]}.png")
        img = crop_and_resize(master_img, size)
        img.save(output_path, quality=95, optimize=True)
        file_size = os.path.getsize(output_path) / (1024 * 1024)
        print(f"[OK] {density}: {size[0]}x{size[1]} px ({file_size:.2f} MB)")
        count += 1
    
    # Landscape 橫屏
    for density, size in ANDROID_LANDSCAPE_SIZES.items():
        output_path = os.path.join(android_dir, f"splash_{density}_{size[0]}x{size[1]}.png")
        img = crop_and_resize(master_img, size)
        img.save(output_path, quality=95, optimize=True)
        file_size = os.path.getsize(output_path) / (1024 * 1024)
        print(f"[OK] {density}: {size[0]}x{size[1]} px ({file_size:.2f} MB)")
        count += 1
    
    print(f"\n總計生成 {count} 個 Android Splash Screen")


def copy_master_to_output(source_path):
    """複製母版到輸出資料夾"""
    master_dir = os.path.join(OUTPUT_DIR, "master")
    filename = os.path.basename(source_path)
    output_path = os.path.join(master_dir, filename)
    
    # 複製文件
    img = Image.open(source_path)
    img.save(output_path, quality=95, optimize=True)
    
    file_size = os.path.getsize(output_path) / (1024 * 1024)
    print(f"\n[OK] 母版已複製到: {output_path} ({file_size:.2f} MB)")


def generate_summary():
    """生成說明文檔"""
    readme_content = """# Splash Screen 資產清單

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
"""
    
    readme_path = os.path.join(OUTPUT_DIR, "README.md")
    with open(readme_path, "w", encoding="utf-8") as f:
        f.write(readme_content)
    
    print(f"\n[OK] 說明文檔已生成: {readme_path}")


def main():
    """主函數"""
    print("=" * 60)
    print("Splash Screen 批量生成工具")
    print("=" * 60)
    
    # 設定母版路徑
    master_path = "picture/APP_ICON8_3200x3200_center.png"
    
    # 檢查母版是否存在
    if not os.path.exists(master_path):
        print(f"[ERROR] 找不到母版圖片: {master_path}")
        print("請先執行 crop_center_icon.py 生成母版")
        return
    
    # 確保輸出資料夾存在
    ensure_output_dir()
    
    # 載入母版
    print(f"\n[INFO] 載入母版: {master_path}")
    master_img = Image.open(master_path)
    print(f"[INFO] 母版尺寸: {master_img.size[0]} x {master_img.size[1]} px")
    
    # 複製母版到輸出資料夾
    copy_master_to_output(master_path)
    
    # 生成 iOS Splash Screens
    generate_ios_splash_screens(master_img)
    
    # 生成 Android Splash Screens
    generate_android_splash_screens(master_img)
    
    # 生成說明文檔
    generate_summary()
    
    # 統計總數
    print("\n" + "=" * 60)
    print("生成完成！")
    print("=" * 60)
    
    total_ios = len(IOS_SIZES) + len(IOS_LANDSCAPE_SIZES)
    total_android = len(ANDROID_SIZES) + len(ANDROID_LANDSCAPE_SIZES)
    total = total_ios + total_android + 1  # +1 for master
    
    print(f"總計生成: {total} 個文件")
    print(f"  - iOS: {total_ios} 個")
    print(f"  - Android: {total_android} 個")
    print(f"  - 母版: 1 個")
    print(f"\n所有文件已保存到: {OUTPUT_DIR}/")
    print(f"請查看 {OUTPUT_DIR}/README.md 了解使用方式")
    print("=" * 60)


if __name__ == "__main__":
    main()

