FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/requirements.txt
RUN pip install --upgrade pip && pip install -r requirements.txt

# Копіюємо весь код (поки що порожній, далі згенеруємо startproject)
COPY app /app/app

# Стандартний порт Django/ Gunicorn
EXPOSE 8000

CMD ["bash", "-lc", \
     "cd app && \
      python manage.py migrate && \
      gunicorn core.wsgi:application --bind 0.0.0.0:8000"]
