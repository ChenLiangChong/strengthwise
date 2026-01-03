#!/usr/bin/env python3
"""
創建 Android Adaptive Icon 專用的圖標
在原圖周圍添加透明邊距，確保不會被裁切
"""

import os
import sys
from PIL import Image

def create_adaptive_icon(input_path, output_path, padding_percent=20):
    """
    創建帶邊距的圖標
    
    Args:
        input_path: 輸入圖片路徑
        output_path: 輸出圖片路徑
        padding_percent: 邊距百分比（建議 15-25%）
    """
    print(f"[INPUT] {input_path}")
    print(f"[OUTPUT] {output_path}")
    print(f"[PADDING] {padding_percent}%")
    print("")
    
    # 讀取原圖
    img = Image.open(input_path)
    original_size = img.size
    print(f"[SIZE] Original: {original_size[0]}x{original_size[1]}")
    
    # 計算新尺寸（保持原尺寸，但內容縮小）
    padding = int(original_size[0] * padding_percent / 100)
    inner_size = original_size[0] - (padding * 2)
    
    print(f"[SIZE] Inner content: {inner_size}x{inner_size}")
    print(f"[SIZE] Padding: {padding}px on each side")
    
    # 縮小原圖
    try:
        img_resized = img.resize((inner_size, inner_size), Image.Resampling.LANCZOS)
    except AttributeError:
        # 舊版 PIL
        img_resized = img.resize((inner_size, inner_size), Image.LANCZOS)
    
    # 創建透明背景的新圖
    new_img = Image.new('RGBA', original_size, (255, 255, 255, 0))
    
    # 將縮小的圖片貼到中央
    position = ((original_size[0] - inner_size) // 2,
                (original_size[1] - inner_size) // 2)
    new_img.paste(img_resized, position, img_resized if img_resized.mode == 'RGBA' else None)
    
    # 儲存
    new_img.save(output_path, 'PNG')
    
    print("")
    print("[SUCCESS] Adaptive icon created!")
    print(f"[INFO] The icon is now {100-padding_percent*2}% of the original size")
    print(f"[INFO] Safe area: {inner_size}x{inner_size} px")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python create_adaptive_icon.py <input_image> [output_image] [padding_percent]")
        print("Example: python create_adaptive_icon.py assets/images/app_icon.png assets/images/app_icon_adaptive.png 20")
        sys.exit(1)
    
    input_path = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) >= 3 else input_path.replace('.png', '_adaptive.png')
    padding = int(sys.argv[3]) if len(sys.argv) >= 4 else 20
    
    if not os.path.exists(input_path):
        print(f"[ERROR] File not found: {input_path}")
        sys.exit(1)
    
    create_adaptive_icon(input_path, output_path, padding)

