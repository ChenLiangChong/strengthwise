#!/usr/bin/env python3
"""
圖片中心區域裁剪工具
功能：從原圖中裁剪出中心 3200x3200 的區域
"""

from PIL import Image
import os

def crop_center_square(input_path, output_path, target_size=3200):
    """
    從圖片中心裁剪指定尺寸的正方形區域
    
    Args:
        input_path: 輸入圖片路徑
        output_path: 輸出圖片路徑
        target_size: 目標正方形尺寸（默認 3200px）
    """
    try:
        # 打開原圖
        img = Image.open(input_path)
        width, height = img.size
        
        print(f"原圖尺寸: {width} x {height} px")
        
        # 檢查原圖是否足夠大
        if width < target_size or height < target_size:
            print(f"⚠️  警告：原圖尺寸不足 {target_size}x{target_size}")
            print(f"   將以實際可裁剪的最大尺寸進行裁剪")
            target_size = min(width, height)
        
        # 計算中心裁剪區域的座標
        left = (width - target_size) // 2
        top = (height - target_size) // 2
        right = left + target_size
        bottom = top + target_size
        
        print(f"裁剪區域: ({left}, {top}, {right}, {bottom})")
        
        # 裁剪圖片
        cropped_img = img.crop((left, top, right, bottom))
        
        # 保存圖片
        cropped_img.save(output_path, quality=95, optimize=True)
        
        print(f"[OK] 成功！新圖片已保存: {output_path}")
        print(f"   新圖片尺寸: {cropped_img.size[0]} x {cropped_img.size[1]} px")
        
        # 顯示文件大小
        input_size = os.path.getsize(input_path) / (1024 * 1024)
        output_size = os.path.getsize(output_path) / (1024 * 1024)
        print(f"   原圖大小: {input_size:.2f} MB")
        print(f"   新圖大小: {output_size:.2f} MB")
        
    except FileNotFoundError:
        print(f"[ERROR] 錯誤：找不到文件 {input_path}")
    except Exception as e:
        print(f"[ERROR] 錯誤：{str(e)}")


if __name__ == "__main__":
    # 配置參數
    input_file = "picture/APP ICON8.png"
    output_file = "picture/APP_ICON8_3200x3200_center.png"
    
    print("=" * 60)
    print("圖片中心區域裁剪工具")
    print("=" * 60)
    
    # 執行裁剪
    crop_center_square(input_file, output_file, target_size=3200)
    
    print("=" * 60)

