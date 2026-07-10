# Django LMS Deployment on Render

Render is a modern cloud platform that's easier than Heroku in many ways and offers generous free tier options.

## Quick Start (15 minutes)

### Prerequisites:
1. Render account: https://render.com (free)
2. GitHub repository with your code
3. PostgreSQL database (free tier available)

### Step-by-Step Deployment:

#### 1. Connect GitHub to Render
- Go to https://dashboard.render.com
- Click "New +"
- Select "Web Service"
- Connect your GitHub account
- Select your `LMS-django-` repository

#### 2. Configure Web Service
Fill in the following:

| Field | Value |
|-------|-------|
| **Name** | lms-django (or your preferred name) |
| **Environment** | Python 3 |
| **Build Command** | `pip install -r requirements/production.txt && python manage.py collectstatic --noinput` |
| **Start Command** | `python -m gunicorn SMS.wsgi:application` |
| **Instance Type** | Free (or Starter+) |

#### 3. Add Environment Variables
Click "Environment" and add these variables:

```
DEBUG=False                    # CRITICAL for production
SECRET_KEY=<your-secure-key>  # Generate: secrets.token_urlsafe(50)
ALLOWED_HOSTS=<your-domain>   # Your domain
DATABASE_URL=<render-postgres> # Auto-filled if using Render DB
USE_S3=False
PYTHON_VERSION=3.9.13
```

#### 4. Create PostgreSQL Database
- In Render Dashboard, click "New +"
- Select "PostgreSQL"
- Name: `lms-db`
- PostgreSQL Version: 14+
- Instance Type: Free

Copy the connection string and set it as `DATABASE_URL` environment variable.

#### 5. Deploy
Click "Create Web Service" to start deployment.

#### 6. Run Migrations
After deployment succeeds:
```bash
# Use Render Shell (in dashboard) or SSH
python manage.py migrate
python manage.py createsuperuser
```

---

## Complete Render Configuration File (render.yaml)

Create this file in your project root for Infrastructure as Code approach:

```yaml
services:
  - type: web
    name: lms-django
    env: python
    plan: free
    buildCommand: pip install -r requirements/production.txt && python manage.py collectstatic --noinput
    startCommand: python -m gunicorn SMS.wsgi:application
    envVars:
      - key: DEBUG
        value: false
      - key: PYTHON_VERSION
        value: 3.9.13
      - key: SECRET_KEY
        sync: false
      - key: DATABASE_URL
        fromDatabase:
          name: lms-db
          property: connectionString
      - key: ALLOWED_HOSTS
        value: ${{ RENDER_EXTERNAL_HOSTNAME }}

databases:
  - name: lms-db
    plan: free
    postgresSQLVersion: 14
```

---

## Environment Variables for Render

Required variables to set in Render Dashboard:

```env
# Django core
DEBUG=False
SECRET_KEY=use-django-secret-key-generator-or-secrets-token

# Hosts
ALLOWED_HOSTS=your-app-name.onrender.com,yourdomain.com,www.yourdomain.com

# Database (auto-filled if using render.yaml)
DATABASE_URL=postgresql://user:pass@host:5432/dbname

# Static files (use Render's static hosting or S3)
USE_S3=False
STATIC_URL=/static/
MEDIA_URL=/media/

# Python
PYTHON_VERSION=3.9.13

# Security (Render handles HTTPS automatically)
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
```

---

## Advanced: Using AWS S3 with Render

If you want to use S3 for static and media files:

```env
USE_S3=True
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
AWS_STORAGE_BUCKET_NAME=your-bucket-name
AWS_S3_REGION_NAME=us-east-1
```

---

## Custom Domain Setup

1. In Render Dashboard, go to your Web Service
2. Click "Settings"
3. Under "Custom Domains", add your domain
4. Render will provide DNS records to update at your domain registrar

Example:
- Domain: `yourlms.com`
- Add CNAME: `yourlms.com` → `your-app-name.onrender.com`

---

## Deployment Workflow

### Automatic Deployment (Recommended)
- Push to main branch → Render auto-deploys
- Configure webhooks in Settings → Deploy Hooks

### Manual Deployment
- Go to Web Service dashboard
- Click "Manual Deploy"
- Select branch and click "Deploy"

---

## Troubleshooting

### Build Fails
Check build logs:
1. Go to your Web Service
2. Click "Logs"
3. Look for error messages

Common issues:
- **ModuleNotFoundError**: Add module to requirements.txt
- **Database connection error**: Check DATABASE_URL format
- **Static files not loading**: Ensure collectstatic runs in build command

### App Crashes After Deploy
```bash
# View runtime logs
# In Render dashboard: Logs tab → see detailed errors

# Common fixes:
# 1. Missing environment variables → add in Settings
# 2. Database migration failed → run manually
# 3. Static files missing → rebuild
```

### Database Issues
- Render free tier PostgreSQL: 90-day rotation
- Backup database regularly
- Free tier databases are destroyed after 90 days of inactivity

---

## Upgrading from Free to Paid Tiers

Render tiers:
- **Free**: Perfect for testing, auto-sleeps after 15 min inactivity
- **Starter** ($7/month): Always on, better performance
- **Standard** ($12/month): Production-ready with more resources
- **Premium**: Enterprise features

To upgrade:
1. Go to Web Service Settings
2. Change "Instance Type"
3. Select paid tier
4. Confirm upgrade

---

## Comparison: Render vs Heroku vs AWS

| Feature | Render | Heroku | AWS |
|---------|--------|--------|-----|
| **Free Tier** | Yes ✓ | Limited | No |
| **Ease of Use** | Very Easy | Very Easy | Complex |
| **PostgreSQL** | Free tier ✓ | Paid only | Self-managed |
| **Static Files** | Included ✓ | Limited | S3 required |
| **Price** | $7+/month | $7+/month | Pay-as-you-go |
| **Sleep Timeout** | 15 min (free) | 30 min | None |
| **SSL Certificate** | Auto ✓ | Auto ✓ | Self-managed |

---

## Next Steps

1. ✅ Create Render account
2. ✅ Connect GitHub repo
3. ✅ Create PostgreSQL database
4. ✅ Deploy Web Service
5. ✅ Add environment variables
6. ✅ Run migrations: `python manage.py migrate`
7. ✅ Create admin: `python manage.py createsuperuser`
8. ✅ Set up custom domain (optional)
9. ✅ Configure email (AWS SES or SendGrid)

---

## Monitoring & Logs

### Real-time Logs
- Render Dashboard → Logs tab
- Shows build and runtime logs

### Metrics
- Dashboard → Metrics
- CPU, Memory, Network usage
- Response times

### Alerts
Set up alerts for:
- High CPU usage
- High memory usage
- Failed deployments
- Frequent restarts

---

## Additional Resources

- Render Docs: https://render.com/docs
- Django + Render Guide: https://render.com/docs/deploy-django
- Troubleshooting: https://render.com/docs/troubleshooting
