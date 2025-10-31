# Dockerfile para Vote App (Flask/Python)
FROM python:3.12-slim

# Establecer el directorio de trabajo
WORKDIR /app

# Instalar dependencias del sistema necesarias para psycopg2
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Copiar archivos de dependencias
COPY requirements.txt .

# Instalar dependencias de Python
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código de la aplicación
COPY . .

# Exponer el puerto
EXPOSE 80

# Configurar variables de entorno por defecto
ENV FLASK_APP=app.py
ENV REDIS_HOST=redis
ENV DATABASE_HOST=database
ENV DATABASE_USER=postgres
ENV DATABASE_PASSWORD=postgres
ENV DATABASE_NAME=votes

# Comando para ejecutar la aplicación con gunicorn
CMD ["gunicorn", "-b", "0.0.0.0:80", "-w", "4", "--log-level", "info", "app:app"]
