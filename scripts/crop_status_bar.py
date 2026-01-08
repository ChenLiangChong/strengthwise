#!/usr/bin/env python3
"""
裁剪截圖頂部狀態列
"""

from PIL import Image
import os

def crop_top(input_path: str, output_path: str, top_pixels: int = 53):
    """裁剪圖片頂部指定像素"""
    with Image.open(input_path) as img:
        width, height = img.size
        # 裁剪：左, 上, 右, 下
        cropped = img.crop((0, top_pixels, width, height))
        cropped.save(output_path, quality=95)
        new_height = height - top_pixels
        print(f"  {os.path.basename(input_path)}: {width}x{height} -> {width}x{new_height}")
        return output_path

def main():
    input_dir = "picture/realIcon/screenshot"
    output_dir = "picture/realIcon/screenshot_cropped"
    top_pixels = 53
    
    # 建立輸出資料夾
    os.makedirs(output_dir, exist_ok=True)
    
    print("=" * 50)
    print(f"裁剪截圖頂部 {top_pixels} 像素（移除狀態列）")
    print("=" * 50)
    print(f"輸入資料夾: {input_dir}")
    print(f"輸出資料夾: {output_dir}")
    print("-" * 50)
    
    count = 0
    for filename in os.listdir(input_dir):
        if filename.lower().endswith(('.jpg', '.jpeg', '.png')):
            input_path = os.path.join(input_dir, filename)
            output_path = os.path.join(output_dir, filename)
            crop_top(input_path, output_path, top_pixels)
            count += 1
    
    print("-" * 50)
    print(f"完成！共處理 {count} 張圖片")
    print(f"輸出位置: {output_dir}")
    print("=" * 50)

if __name__ == "__main__":
    main()

