#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-8000}"

python -m pip install --disable-pip-version-check -q -r requirements/production.txt || true
python -m pip install --disable-pip-version-check -q gunicorn==20.1.0 || true

exec python -m gunicorn --bind 0.0.0.0:${PORT} SMS.wsgi:application
