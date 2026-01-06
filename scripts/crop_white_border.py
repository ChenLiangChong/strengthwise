#!/usr/bin/env python3
"""
裁切圖片白邊工具
"""
from PIL import Image
import os

def fill_light_areas(input_path, output_path, threshold=200, fill_color=(10, 22, 40)):
    """
    從圖片四周邊緣開始，填充連續的淺色區域（flood fill）
    
    Args:
        input_path: 輸入圖片路徑
        output_path: 輸出圖片路徑
        threshold: 白色閾值（0-255），RGB 都大於此值的像素會被填色
        fill_color: 填充顏色 RGB tuple，預設 #0A1628 = (10, 22, 40)
    """
    from collections import deque
    
    # 開啟圖片
    img = Image.open(input_path)
    
    # 轉換為 RGBA
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    # 取得像素資料
    pixels = img.load()
    width, height = img.size
    
    # 標記已訪問的像素
    visited = set()
    
    def is_light(x, y):
        """判斷像素是否為淺色"""
        if x < 0 or x >= width or y < 0 or y >= height:
            return False
        r, g, b, a = pixels[x, y]
        return r > threshold and g > threshold and b > threshold
    
    def flood_fill_from_edges():
        """從邊緣開始 flood fill"""
        queue = deque()
        filled = 0
        
        # 加入四邊的所有像素作為起點
        for x in range(width):
            if is_light(x, 0):
                queue.append((x, 0))
            if is_light(x, height - 1):
                queue.append((x, height - 1))
        for y in range(height):
            if is_light(0, y):
                queue.append((0, y))
            if is_light(width - 1, y):
                queue.append((width - 1, y))
        
        # BFS flood fill
        while queue:
            x, y = queue.popleft()
            
            if (x, y) in visited:
                continue
            if x < 0 or x >= width or y < 0 or y >= height:
                continue
            if not is_light(x, y):
                continue
                
            visited.add((x, y))
            
            # 填色
            pixels[x, y] = (fill_color[0], fill_color[1], fill_color[2], 255)
            filled += 1
            
            # 加入鄰居
            queue.append((x + 1, y))
            queue.append((x - 1, y))
            queue.append((x, y + 1))
            queue.append((x, y - 1))
        
        return filled
    
    filled_count = flood_fill_from_edges()
    
    # 儲存
    img.save(output_path, 'PNG')
    
    print(f"[OK] Processed: {os.path.basename(input_path)}")
    print(f"     Size: {width}x{height}")
    print(f"     Filled {filled_count} pixels with #0A1628")
    print(f"     Output: {output_path}")
    
    return (width, height)

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    input_dir = os.path.join(base_dir, "picture", "realIcon")
    output_dir = os.path.join(base_dir, "assets")
    
    # 確保輸出目錄存在
    os.makedirs(os.path.join(output_dir, "icon"), exist_ok=True)
    os.makedirs(os.path.join(output_dir, "splash"), exist_ok=True)
    
    # 處理 App Icon - 填充淺色為 #0A1628
    icon_input = os.path.join(input_dir, "APP ICON4.png")
    icon_output = os.path.join(output_dir, "icon", "icon.png")
    fill_light_areas(icon_input, icon_output)
    
    print()
    
    # 處理 Splash - 填充淺色為 #0A1628
    splash_input = os.path.join(input_dir, "APP ICON6.png")
    splash_output = os.path.join(output_dir, "splash", "splash.png")
    fill_light_areas(splash_input, splash_output)

if __name__ == "__main__":
    main()

