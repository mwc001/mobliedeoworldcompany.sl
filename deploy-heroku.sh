#!/bin/bash

# Quick Heroku Deployment Script for Django LMS
# This script automates the deployment to Heroku

set -e  # Exit on error

echo "🚀 Django LMS Heroku Deployment Script"
echo "======================================="
echo ""

# Check if Heroku CLI is installed
if ! command -v heroku &> /dev/null; then
    echo "❌ Heroku CLI not found. Installing..."
    curl https://cli-assets.heroku.com/install-ubuntu.sh | sh
fi

echo "✅ Checking Heroku login status..."
if ! heroku auth:whoami &> /dev/null; then
    echo "📝 Please log in to Heroku:"
    heroku login
fi

# Get app name
read -p "Enter Heroku app name (will be created if doesn't exist): " APP_NAME

if [ -z "$APP_NAME" ]; then
    echo "❌ App name cannot be empty!"
    exit 1
fi

# Create app if it doesn't exist
echo "📦 Creating/checking Heroku app: $APP_NAME"
heroku apps:info --app="$APP_NAME" > /dev/null 2>&1 || heroku create "$APP_NAME"

# Get database URL
read -p "Enter your PostgreSQL DATABASE_URL (or press Enter to use Heroku Postgres): " DB_URL

if [ -z "$DB_URL" ]; then
    echo "📦 Setting up Heroku Postgres addon..."
    heroku addons:create heroku-postgresql:hobby-dev --app="$APP_NAME" || echo "⚠️  Addon may already exist"
    DB_URL=$(heroku config:get DATABASE_URL --app="$APP_NAME")
fi

# Get SECRET_KEY
read -sp "Enter Django SECRET_KEY (will be hidden): " SECRET_KEY
echo ""

if [ -z "$SECRET_KEY" ]; then
    echo "⚠️  Generating random SECRET_KEY..."
    SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_urlsafe(50))')
fi

# Get domain
read -p "Enter your domain (e.g., yourdomain.com): " DOMAIN

if [ -z "$DOMAIN" ]; then
    DOMAIN="$APP_NAME.herokuapp.com"
fi

# Set environment variables
echo "🔐 Setting environment variables..."
heroku config:set \
    DEBUG=False \
    SECRET_KEY="$SECRET_KEY" \
    ALLOWED_HOSTS="$DOMAIN,www.$DOMAIN,$APP_NAME.herokuapp.com" \
    USE_S3=False \
    --app="$APP_NAME"

# Deploy
echo "📤 Deploying to Heroku..."
git push heroku main

# Run migrations
echo "🗄️  Running database migrations..."
heroku run python manage.py migrate --app="$APP_NAME"

# Collect static files
echo "📦 Collecting static files..."
heroku run python manage.py collectstatic --noinput --app="$APP_NAME"

# Create superuser
echo "👤 Creating superuser..."
heroku run python manage.py createsuperuser --app="$APP_NAME"

# Done
echo ""
echo "✅ Deployment complete!"
echo "🌐 Visit your app at: https://$APP_NAME.herokuapp.com"
echo ""
echo "Next steps:"
echo "1. Configure your domain: heroku domains:add $DOMAIN --app=$APP_NAME"
echo "2. Set up SSL certificate (automatic with Heroku)"
echo "3. Monitor logs: heroku logs --tail --app=$APP_NAME"
