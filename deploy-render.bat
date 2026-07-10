@echo off
REM Render Deployment Script for Django LMS (Windows)
REM This script helps set up your Django LMS on Render

echo.
echo 🚀 Django LMS Render Deployment Setup (Windows)
echo ================================================
echo.

REM Check if render.yaml exists
if exist "render.yaml" (
    echo ✅ render.yaml found in project
) else (
    echo ❌ render.yaml not found. Please ensure it exists in project root.
    pause
    exit /b 1
)

echo.
echo 📋 Deployment Steps:
echo ====================
echo.
echo 1. Push your code to GitHub:
echo    git add .
echo    git commit -m "Prepare for Render deployment"
echo    git push origin main
echo.

echo 2. Go to Render Dashboard:
echo    https://dashboard.render.com
echo.

echo 3. Create New Web Service:
echo    - Click "New +" menu
echo    - Select "Web Service"
echo    - Connect your GitHub repository
echo    - Select your LMS-django- repository
echo.

echo 4. Configure Web Service:
echo    - Name: lms-django (or your preference)
echo    - Environment: Python 3
echo    - Region: Choose closest to you
echo    - Build Command: pip install -r requirements/production.txt ^&^& python manage.py collectstatic --noinput
echo    - Start Command: python -m gunicorn SMS.wsgi:application
echo    - Instance Type: Free (or Starter+)
echo.

echo 5. Add Environment Variables:
echo    Click "Environment" and add:
echo    - DEBUG=False
echo    - SECRET_KEY=use-strong-random-key
echo    - ALLOWED_HOSTS=your-app.onrender.com,yourdomain.com
echo    - DATABASE_URL=postgres://... ^(from database step^)
echo.

echo 6. Create PostgreSQL Database:
echo    - Click "New +" menu
echo    - Select "PostgreSQL"
echo    - Name: lms-db
echo    - PostgreSQL Version: 14 or higher
echo    - Instance Type: Free
echo    - Copy "Internal Database URL" to DATABASE_URL
echo.

echo 7. Deploy!
echo    - Click "Create Web Service"
echo    - Monitor build progress
echo    - Wait for "Live" status
echo.

echo 8. Run Migrations:
echo    After deployment succeeds:
echo    - Use Render Shell from dashboard
echo    - Run: python manage.py migrate
echo    - Run: python manage.py createsuperuser
echo.

echo 9. Visit your app:
echo    https://your-app-name.onrender.com
echo.

echo ✅ Setup complete! Follow the steps above to deploy to Render.
echo.
echo Need help?
echo - Render Docs: https://render.com/docs
echo - Django Guide: https://render.com/docs/deploy-django
echo.

pause

DEBUG=False
ALLOWED_HOSTS=mobliedeoworldcompany-sl.onrender.com
DATABASE_URL=postgresql://<db-user>:<db-password>@<db-host>:5432/<db-name>
SECRET_KEY=<your-secret-key>
USE_S3=False
PYTHON_VERSION=3.9.13
