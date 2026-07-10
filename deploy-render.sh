#!/bin/bash

# Render Deployment Script for Django LMS
# This script helps set up your Django LMS on Render
# Prerequisites: Git, GitHub account, Render account

set -e

echo "🚀 Django LMS Render Deployment Setup"
echo "======================================"
echo ""

# Check if render.yaml exists
if [ -f "render.yaml" ]; then
    echo "✅ render.yaml found in project"
else
    echo "❌ render.yaml not found. Please ensure it exists in project root."
    exit 1
fi

echo ""
echo "📋 Deployment Steps:"
echo "===================="
echo ""
echo "1. Push your code to GitHub:"
echo "   git add ."
echo "   git commit -m 'Prepare for Render deployment'"
echo "   git push origin main"
echo ""

echo "2. Go to Render Dashboard:"
echo "   https://dashboard.render.com"
echo ""

echo "3. Create New Web Service:"
echo "   - Click 'New +' → 'Web Service'"
echo "   - Connect your GitHub repository"
echo "   - Select your LMS-django- repo"
echo ""

echo "4. Configure Web Service:"
echo "   - Name: lms-django (or your preference)"
echo "   - Environment: Python 3"
echo "   - Build: pip install -r requirements/production.txt && python manage.py collectstatic --noinput"
echo "   - Start: python -m gunicorn SMS.wsgi:application"
echo "   - Instance Type: Free (or Starter+)"
echo ""

echo "5. Add Environment Variables:"
echo "   Click 'Environment' and add:"
echo "   - DEBUG=False"
echo "   - SECRET_KEY=<your-secure-key>"
echo "   - ALLOWED_HOSTS=your-app.onrender.com,yourdomain.com"
echo "   - DATABASE_URL=<from PostgreSQL service>"
echo ""

echo "6. Create PostgreSQL Database:"
echo "   - Click 'New +' → 'PostgreSQL'"
echo "   - Name: lms-db"
echo "   - Plan: Free"
echo "   - Copy connection string to DATABASE_URL"
echo ""

echo "7. Deploy!"
echo "   - Click 'Create Web Service'"
echo "   - Wait for build to complete"
echo ""

echo "8. Run Migrations:"
echo "   - Use Render Shell or SSH"
echo "   - Run: python manage.py migrate"
echo "   - Run: python manage.py createsuperuser"
echo ""

echo "9. Visit your app:"
echo "   https://your-app-name.onrender.com"
echo ""

echo "✅ Setup complete! Follow the steps above to deploy to Render."
echo ""
echo "Need help? Visit:"
echo "- Render Docs: https://render.com/docs"
echo "- Django Guide: https://render.com/docs/deploy-django"
