#!/usr/bin/env python3
"""
圖片去背工具

使用 rembg 套件自動去除圖片背景
"""

import os
import sys
from pathlib import Path

def main():
    """主函數"""
    if len(sys.argv) < 2:
        print("❌ 使用方式: python remove_background.py <input_image> [output_image]")
        print("   範例: python remove_background.py picture/APP_ICON4.png picture/APP_ICON4_transparent.png")
        sys.exit(1)
    
    input_path = sys.argv[1]
    
    # 如果沒有指定輸出路徑，自動生成
    if len(sys.argv) >= 3:
        output_path = sys.argv[2]
    else:
        # 在原檔名後加上 _transparent
        path = Path(input_path)
        output_path = str(path.parent / f"{path.stem}_transparent{path.suffix}")
    
    # 檢查輸入檔案是否存在
    if not os.path.exists(input_path):
        print(f"❌ 找不到檔案: {input_path}")
        sys.exit(1)
    
    print(f"[INPUT] {input_path}")
    print(f"[OUTPUT] {output_path}")
    print("")
    
    # 檢查是否已安裝 rembg
    try:
        from rembg import remove
        from PIL import Image
    except ImportError:
        print("[ERROR] rembg not found!")
        print("")
        print("Install command:")
        print("   pip install rembg pillow")
        sys.exit(1)
    
    print("[PROCESSING] Removing background...")
    
    try:
        # 讀取圖片
        input_image = Image.open(input_path)
        
        # 去背
        output_image = remove(input_image)
        
        # 儲存
        output_image.save(output_path)
        
        print("")
        print("[SUCCESS] Background removed!")
        print(f"[SAVED] {output_path}")
        
        # 顯示檔案大小
        input_size = os.path.getsize(input_path) / 1024
        output_size = os.path.getsize(output_path) / 1024
        print(f"[SIZE] Original: {input_size:.1f} KB")
        print(f"[SIZE] Output: {output_size:.1f} KB")
        
    except Exception as e:
        print(f"[ERROR] {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

