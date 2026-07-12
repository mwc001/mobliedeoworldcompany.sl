#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-8000}"
export DJANGO_SETTINGS_MODULE="${DJANGO_SETTINGS_MODULE:-SMS.settings}"

python -m pip install --disable-pip-version-check -q -r requirements/production.txt || true
python -m pip install --disable-pip-version-check -q gunicorn==20.1.0 || true
python manage.py collectstatic --noinput || true
python manage.py migrate --noinput || true

exec python -m gunicorn --bind 0.0.0.0:${PORT} SMS.wsgi:application
