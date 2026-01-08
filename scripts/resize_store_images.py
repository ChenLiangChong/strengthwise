#!/usr/bin/env python3
"""
調整 Google Play 商店所需圖片尺寸
- App Icon: 512 x 512 px
- Feature Graphic: 1024 x 500 px
"""

from PIL import Image
import os

def resize_app_icon(input_path: str, output_path: str = None):
    """調整 App Icon 為 512x512"""
    if output_path is None:
        base, ext = os.path.splitext(input_path)
        output_path = f"{base}_512x512{ext}"
    
    with Image.open(input_path) as img:
        # 轉換為 RGBA（如果需要）
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # 調整尺寸，保持品質
        resized = img.resize((512, 512), Image.Resampling.LANCZOS)
        
        # 儲存為 PNG
        output_png = output_path.rsplit('.', 1)[0] + '.png'
        resized.save(output_png, 'PNG', optimize=True)
        
        file_size = os.path.getsize(output_png) / 1024  # KB
        print(f"✅ App Icon 已儲存: {output_png}")
        print(f"   尺寸: 512 x 512 px")
        print(f"   大小: {file_size:.1f} KB")
        
        return output_png

def resize_feature_graphic(input_path: str, output_path: str = None, bg_color: str = "#0A1628"):
    """調整 Feature Graphic 為 1024x500，保持比例並填充背景"""
    if output_path is None:
        base, ext = os.path.splitext(input_path)
        output_path = f"{base}_1024x500{ext}"
    
    # 解析背景顏色
    bg_color = bg_color.lstrip('#')
    bg_rgb = tuple(int(bg_color[i:i+2], 16) for i in (0, 2, 4))
    
    with Image.open(input_path) as img:
        # 轉換為 RGBA
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # 建立目標尺寸的背景
        target_width, target_height = 1024, 500
        background = Image.new('RGBA', (target_width, target_height), (*bg_rgb, 255))
        
        # 計算縮放比例（保持原圖比例，fit 進目標區域）
        img_ratio = img.width / img.height
        target_ratio = target_width / target_height
        
        if img_ratio > target_ratio:
            # 圖片較寬，以寬度為準
            new_width = int(target_width * 0.8)  # 留邊距
            new_height = int(new_width / img_ratio)
        else:
            # 圖片較高，以高度為準
            new_height = int(target_height * 0.8)  # 留邊距
            new_width = int(new_height * img_ratio)
        
        # 調整圖片尺寸
        resized_img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
        
        # 置中貼上
        x = (target_width - new_width) // 2
        y = (target_height - new_height) // 2
        background.paste(resized_img, (x, y), resized_img)
        
        # 轉換為 RGB（PNG 不需要 alpha）
        final = background.convert('RGB')
        
        # 儲存
        output_png = output_path.rsplit('.', 1)[0] + '.png'
        final.save(output_png, 'PNG', optimize=True)
        
        file_size = os.path.getsize(output_png) / 1024  # KB
        print(f"✅ Feature Graphic 已儲存: {output_png}")
        print(f"   尺寸: 1024 x 500 px")
        print(f"   大小: {file_size:.1f} KB")
        
        return output_png

def create_simple_feature_graphic(logo_path: str, output_path: str = "picture/feature_graphic.png", bg_color: str = "#0A1628"):
    """用 Logo 建立簡單的 Feature Graphic"""
    return resize_feature_graphic(logo_path, output_path, bg_color)

if __name__ == "__main__":
    import sys
    
    print("=" * 50)
    print("Google Play 商店圖片調整工具")
    print("=" * 50)
    
    # 預設路徑
    icon_source = "picture/realIcon/APP_ICON4-filled.png"
    logo_source = "picture/APP_ICON4-removebg.png"
    
    # 檢查來源檔案
    if os.path.exists(icon_source):
        print(f"\n📱 處理 App Icon: {icon_source}")
        resize_app_icon(icon_source, "picture/store_icon_512x512.png")
    else:
        print(f"⚠️ 找不到 App Icon: {icon_source}")
        print("   請提供 App Icon 圖片路徑")
    
    if os.path.exists(logo_source):
        print(f"\n🖼️ 處理 Feature Graphic: {logo_source}")
        create_simple_feature_graphic(logo_source, "picture/feature_graphic_1024x500.png")
    else:
        print(f"⚠️ 找不到 Logo: {logo_source}")
        print("   請提供 Logo 圖片路徑")
    
    print("\n" + "=" * 50)
    print("完成！請上傳以下檔案到 Google Play Console:")
    print("1. picture/store_icon_512x512.png (App Icon)")
    print("2. picture/feature_graphic_1024x500.png (Feature Graphic)")
    print("=" * 50)

