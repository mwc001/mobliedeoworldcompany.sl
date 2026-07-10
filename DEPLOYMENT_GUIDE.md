# Django LMS Deployment Guide

## Quick Deployment Options

### 1. **Heroku (Easiest - Recommended for beginners)**
**Time: ~15 minutes**

#### Prerequisites:
- Heroku account (free tier available)
- Heroku CLI installed

#### Steps:
```bash
# Install Heroku CLI: https://devcenter.heroku.com/articles/heroku-cli

# Login to Heroku
heroku login

# Create Procfile in project root
# Add this content to Procfile:
# web: gunicorn SMS.wsgi

# Create runtime.txt
# Add: python-3.9.13

# Create .env file locally (for reference, don't commit)
DEBUG=False
SECRET_KEY=your-production-secret-key
ALLOWED_HOSTS=yourdomain.herokuapp.com

# Push to Heroku
heroku create your-app-name
git push heroku main

# Run migrations on Heroku
heroku run python manage.py migrate

# Create superuser
heroku run python manage.py createsuperuser

# Collect static files
heroku run python manage.py collectstatic --noinput
```

---

### 2. **AWS (More Control & Scalability)**
**Time: ~1 hour**

#### Services needed:
- EC2 (for app server)
- RDS (for PostgreSQL database)
- S3 (for static/media files)
- CloudFront (optional, for CDN)

#### Steps:
```bash
# 1. Create RDS PostgreSQL instance
# - Go to AWS RDS Console
# - Create PostgreSQL database
# - Save endpoint, username, password

# 2. Create EC2 instance
# - Ubuntu 20.04 LTS recommended
# - t2.micro (free tier) or t2.small

# 3. SSH into your EC2 instance and run:
sudo apt update
sudo apt install python3-pip python3-venv postgresql-client nginx git

# 4. Clone your repository
cd /var/www
git clone your-repo-url
cd LMS-django-
python3 -m venv venv
source venv/bin/activate

# 5. Install dependencies
pip install -r requirements/production.txt

# 6. Create .env file
cat > .env << EOF
DEBUG=False
SECRET_KEY=your-secure-secret-key-here
ALLOWED_HOSTS=your-domain.com,www.your-domain.com
DATABASE_URL=postgresql://username:password@your-rds-endpoint:5432/dbname
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_STORAGE_BUCKET_NAME=your-bucket-name
EOF

# 7. Run migrations
python manage.py migrate

# 8. Create superuser
python manage.py createsuperuser

# 9. Collect static files to S3
python manage.py collectstatic --noinput

# 10. Configure Gunicorn
pip install gunicorn
gunicorn --workers 3 --bind 127.0.0.1:8000 SMS.wsgi

# 11. Create systemd service file for Gunicorn
sudo nano /etc/systemd/system/gunicorn.service
# Add content from below

# 12. Configure Nginx as reverse proxy
sudo nano /etc/nginx/sites-available/default
# Add content from below
```

---

### 3. **DigitalOcean (Middle ground)**
**Time: ~45 minutes**

- Similar to AWS but simpler interface
- $4/month droplet sufficient
- Use 1-Click Django app deployment

---

## Production Settings Checklist

### Update settings.py for production:

```python
# SMS/settings.py

DEBUG = False  # CRITICAL!

# Get from environment
import os
from pathlib import Path

SECRET_KEY = os.environ.get('SECRET_KEY')

ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '').split(',')

# Database - use PostgreSQL
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME'),
        'USER': os.environ.get('DB_USER'),
        'PASSWORD': os.environ.get('DB_PASSWORD'),
        'HOST': os.environ.get('DB_HOST'),
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}

# Static files - use S3
USE_S3 = os.environ.get('USE_S3') == 'True'

if USE_S3:
    AWS_STORAGE_BUCKET_NAME = os.environ.get('AWS_STORAGE_BUCKET_NAME')
    AWS_S3_REGION_NAME = os.environ.get('AWS_S3_REGION_NAME', 'us-east-1')
    AWS_S3_CUSTOM_DOMAIN = f'{AWS_STORAGE_BUCKET_NAME}.s3.amazonaws.com'
    AWS_S3_OBJECT_PARAMETERS = {'CacheControl': 'max-age=86400'}
    
    STATIC_URL = f'https://{AWS_S3_CUSTOM_DOMAIN}/static/'
    STATIC_ROOT = 'static/'
    STATICFILES_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
    
    MEDIA_URL = f'https://{AWS_S3_CUSTOM_DOMAIN}/media/'
    MEDIA_ROOT = 'media/'
    DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3StaticStorage'
else:
    STATIC_URL = '/static/'
    STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
    MEDIA_URL = '/media/'
    MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# Security
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_SECURITY_POLICY = {
    'default-src': ("'self'",),
}

# Email - AWS SES
EMAIL_BACKEND = 'django_anymail.backends.amazon_ses.EmailBackend'
AWS_SES_REGION_NAME = os.environ.get('AWS_SES_REGION_NAME', 'us-east-1')

# CORS
CORS_ALLOWED_ORIGINS = os.environ.get('CORS_ALLOWED_ORIGINS', '').split(',')
```

---

## Gunicorn Systemd Service File

Create `/etc/systemd/system/gunicorn.service`:

```ini
[Unit]
Description=Gunicorn application server for Django LMS
After=network.target

[Service]
Type=notify
User=www-data
Group=www-data
WorkingDirectory=/var/www/LMS-django-
Environment="PATH=/var/www/LMS-django-/venv/bin"
EnvironmentFile=/var/www/LMS-django-/.env
ExecStart=/var/www/LMS-django-/venv/bin/gunicorn \
    --workers 3 \
    --bind 127.0.0.1:8000 \
    --timeout 120 \
    SMS.wsgi:application

[Install]
WantedBy=multi-user.target
```

Enable & start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable gunicorn
sudo systemctl start gunicorn
```

---

## Nginx Configuration

Create `/etc/nginx/sites-available/lms`:

```nginx
upstream gunicorn {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    client_max_body_size 100M;

    location / {
        proxy_pass http://gunicorn;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        alias /var/www/LMS-django-/staticfiles/;
    }

    location /media/ {
        alias /var/www/LMS-django-/media/;
    }
}
```

Enable:
```bash
sudo ln -s /etc/nginx/sites-available/lms /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## SSL Certificate (Let's Encrypt)

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

---

## Environment Variables Needed

Create `.env` file (example):

```
DEBUG=False
SECRET_KEY=django-insecure-your-secret-key-here
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
DATABASE_URL=postgresql://user:pass@localhost:5432/lmsdb
USE_S3=True
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
AWS_STORAGE_BUCKET_NAME=your-bucket
AWS_S3_REGION_NAME=us-east-1
AWS_SES_REGION_NAME=us-east-1
```

---

## Pre-Deployment Checklist

- [ ] Change `SECRET_KEY` in settings
- [ ] Set `DEBUG = False`
- [ ] Configure database (PostgreSQL recommended)
- [ ] Set up AWS S3 & SES accounts (if using)
- [ ] Create `.env` file with all variables
- [ ] Run `python manage.py check --deploy`
- [ ] Collect static files: `python manage.py collectstatic`
- [ ] Run migrations: `python manage.py migrate`
- [ ] Create superuser: `python manage.py createsuperuser`
- [ ] Test with `gunicorn SMS.wsgi`
- [ ] Configure domain/DNS
- [ ] Set up SSL certificate

---

## Quick Start: Heroku (Recommended)

If you want the **easiest option**, go with **Heroku**:

```bash
# 1. Create Procfile
echo "web: gunicorn SMS.wsgi" > Procfile

# 2. Create runtime.txt
echo "python-3.9.13" > runtime.txt

# 3. Push to Heroku
heroku create your-app-name
git push heroku main
heroku run python manage.py migrate
heroku run python manage.py createsuperuser

# Done! Visit https://your-app-name.herokuapp.com
```

---

## Need Help?

- **Heroku docs**: https://devcenter.heroku.com/articles/getting-started-with-python
- **AWS docs**: https://docs.aws.amazon.com/
- **Django deployment**: https://docs.djangoproject.com/en/stable/howto/deployment/
