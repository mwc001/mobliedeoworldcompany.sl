#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-8000}"
exec python -m gunicorn --bind 0.0.0.0:${PORT} SMS.wsgi:application
