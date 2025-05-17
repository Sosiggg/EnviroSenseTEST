@echo off
setlocal enabledelayedexpansion

REM Check if a commit message was provided
if "%~1"=="" (
    echo Error: Please provide a commit message.
    echo Usage: commit "Your commit message"
    exit /b 1
)

REM Get the commit message
set "message=%~1"

REM Run the git commands
echo Running: git add .
git add .

echo Running: git commit -m "%message%"
git commit -m "%message%"

echo Running: git push
git push

echo Done!
