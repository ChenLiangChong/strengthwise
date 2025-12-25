@echo off
echo StrengthWise - 用戶數據重置工具
echo ========================================
echo.
echo 目標用戶: d1798674-0b96-4c47-a7c7-ee20a5372a03
echo.
echo 此腳本將：
echo   1. 刪除該用戶的所有訓練數據
echo   2. 生成一個月的訓練記錄（推拉腿分化）
echo   3. 生成一周的訓練模板
echo.
echo 警告：此操作將刪除該用戶的所有數據！
echo.

set /p confirm="確定要繼續嗎？(yes/no): "
if /i not "%confirm%"=="yes" (
    if /i not "%confirm%"=="y" (
        echo 操作已取消
        exit /b 0
    )
)

echo.
echo 開始執行...
echo.

python scripts\reset_user_data_and_generate.py d1798674-0b96-4c47-a7c7-ee20a5372a03 --auto-confirm

echo.
echo 完成！
pause

