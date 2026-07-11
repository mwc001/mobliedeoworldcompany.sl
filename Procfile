web: python -m gunicorn --bind 0.0.0.0:$PORT SMS.wsgi:application
worker: celery -A SMS worker -l info
