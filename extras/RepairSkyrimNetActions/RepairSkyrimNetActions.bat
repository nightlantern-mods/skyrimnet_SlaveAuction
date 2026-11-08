@echo off
rem Drop SkyrimNet's Actions.yaml onto this file. See RepairSkyrimNetActions.ps1 for what it changes.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0RepairSkyrimNetActions.ps1" "%~1"
