@echo off
REM Quick Heroku Deployment Script for Django LMS (Windows)
REM This script automates the deployment to Heroku

echo.
echo 🚀 Django LMS Heroku Deployment Script (Windows)
echo ================================================
echo.

REM Check if Heroku CLI is installed
where heroku >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Heroku CLI not found. Please install it from:
    echo    https://devcenter.heroku.com/articles/heroku-cli
    pause
    exit /b 1
)

echo ✅ Heroku CLI found
echo.

REM Check login status
heroku auth:whoami >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo 📝 Please log in to Heroku:
    heroku login
)

REM Get app name
set /p APP_NAME="Enter Heroku app name: "

if "%APP_NAME%"=="" (
    echo ❌ App name cannot be empty!
    pause
    exit /b 1
)

echo.
echo 📦 Creating/checking Heroku app: %APP_NAME%
heroku apps:info --app=%APP_NAME% >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    heroku create %APP_NAME%
)

echo.
set /p DB_URL="Enter DATABASE_URL (press Enter to use Heroku Postgres): "

if "%DB_URL%"=="" (
    echo 📦 Setting up Heroku Postgres...
    heroku addons:create heroku-postgresql:hobby-dev --app=%APP_NAME%
)

echo.
set /p SECRET_KEY="Enter Django SECRET_KEY: "

if "%SECRET_KEY%"=="" (
    echo ⚠️  Using default - CHANGE THIS IN PRODUCTION!
    set SECRET_KEY=change-me-in-production-use-secrets-token
)

echo.
set /p DOMAIN="Enter your domain (e.g., yourdomain.com): "

if "%DOMAIN%"=="" (
    set DOMAIN=%APP_NAME%.herokuapp.com
)

echo.
echo 🔐 Setting environment variables...
heroku config:set DEBUG=False SECRET_KEY="%SECRET_KEY%" ALLOWED_HOSTS="%DOMAIN%,www.%DOMAIN%,%APP_NAME%.herokuapp.com" USE_S3=False --app=%APP_NAME%

echo.
echo 📤 Deploying to Heroku...
git push heroku main

echo.
echo 🗄️  Running database migrations...
heroku run python manage.py migrate --app=%APP_NAME%

echo.
echo 📦 Collecting static files...
heroku run python manage.py collectstatic --noinput --app=%APP_NAME%

echo.
echo ✅ Deployment complete!
echo.
echo 🌐 Visit: https://%APP_NAME%.herokuapp.com
echo.
echo Next: heroku domains:add %DOMAIN% --app=%APP_NAME%
echo.

pause
