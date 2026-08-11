@echo off
setlocal
cd /d "%~dp0"
python -m PyInstaller --noconfirm --clean --onefile --windowed --name "密码机小游戏" --distpath "%~dp0release" --workpath "%~dp0..\..\work\password-machine-build" --specpath "%~dp0" game.py
if errorlevel 1 (
  echo 打包失败。请先运行：python -m pip install pyinstaller
  pause
)
endlocal
