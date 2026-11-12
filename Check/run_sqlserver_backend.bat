@echo off
chcp 65001 >nul
title Secret Santa 2026 - SQL Server Backend API
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start_sqlserver_api.ps1"
pause
