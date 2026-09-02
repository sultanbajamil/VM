@echo off
title VM Hardware Spoofer Launcher
:: تشغيل السكربت الرسومي في الخلفية دون إظهار نافذة الكونسول السوداء
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0spoof_host_vm.ps1"
