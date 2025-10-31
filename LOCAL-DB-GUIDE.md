# 🔌 Guía de Conexión a PostgreSQL Local

## 📋 Descripción

Este docker-compose alternativo (`docker-compose.local-db.yml`) permite que los contenedores se conecten a una base de datos PostgreSQL que ya esté corriendo en tu máquina local, **fuera de Docker**.

## 🎯 Casos de Uso

- Ya tienes PostgreSQL instalado localmente y quieres usarlo
- Necesitas acceder a una base de datos existente
- Quieres desarrollar con datos persistentes fuera de Docker
- Tienes múltiples proyectos compartiendo la misma instancia de PostgreSQL

## ⚙️ Requisitos Previos

### 1. PostgreSQL debe estar instalado y corriendo en tu máquina

Verificar que PostgreSQL está corriendo:

```bash
# Linux/Mac
sudo systemctl status postgresql
# o
pg_isready

# Si usas Docker Desktop, PostgreSQL local debería estar en el puerto 5432
```

### 2. Configurar PostgreSQL para aceptar conexiones

Edita el archivo de configuración de PostgreSQL:

**En Linux:**
```bash
sudo nano /etc/postgresql/[version]/main/postgresql.conf
```

**En Mac (Homebrew):**
```bash
nano /usr/local/var/postgres/postgresql.conf
# o
nano /opt/homebrew/var/postgres/postgresql.conf
```

Asegúrate de que esté configurado para escuchar en localhost:
```conf
listen_addresses = 'localhost'
# o para todas las interfaces:
listen_addresses = '*'
```

### 3. Configurar autenticación (pg_hba.conf)

**En Linux:**
```bash
sudo nano /etc/postgresql/[version]/main/pg_hba.conf
```

**En Mac:**
```bash
nano /usr/local/var/postgres/pg_hba.conf
```

Agregar/modificar esta línea para permitir conexiones locales:
```conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
```

Reiniciar PostgreSQL:
```bash
# Linux
sudo systemctl restart postgresql

# Mac
brew services restart postgresql
```

## 🚀 Pasos de Configuración

### 1. Crear la base de datos y tabla

Ejecuta el script SQL proporcionado:

```bash
# Opción 1: Desde el archivo
psql -U postgres -f setup-local-db.sql

# Opción 2: Conectarse y ejecutar manualmente
psql -U postgres
```

Luego ejecuta:
```sql
CREATE DATABASE votes;
\c votes

CREATE TABLE IF NOT EXISTS votes (
    id VARCHAR(255) PRIMARY KEY,
    vote VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_votes_vote ON votes(vote);
CREATE INDEX IF NOT EXISTS idx_votes_created_at ON votes(created_at);
```

### 2. Configurar variables de entorno

Copia el archivo de ejemplo:
```bash
cp .env.local.example .env.local
```

Edita `.env.local` con tus credenciales:
```bash
DATABASE_USER=postgres
DATABASE_PASSWORD=tu_password_real
DATABASE_NAME=votes
```

### 3. Levantar los servicios

```bash
# Usando el docker-compose específico
docker compose -f docker-compose.local-db.yml --env-file .env.local up -d

# O con Makefile personalizado
make up-local
```

## 🔍 Verificación

### 1. Verificar que los contenedores están corriendo

```bash
docker compose -f docker-compose.local-db.yml ps
```

### 2. Verificar conectividad a la base de datos

Desde dentro del contenedor vote:
```bash
docker exec -it roxs-vote sh

# Probar conexión (necesitarás instalar psql si no está)
# O simplemente verifica los logs
exit

docker compose -f docker-compose.local-db.yml logs vote
```

### 3. Verificar datos en PostgreSQL local

```bash
psql -U postgres -d votes

# Ver votos
SELECT * FROM votes;

# Ver estadísticas
SELECT vote, COUNT(*) FROM votes GROUP BY vote;
```

## 🔧 Troubleshooting

### Problema 1: "Connection refused"

**Solución**: PostgreSQL no está corriendo o no acepta conexiones
```bash
# Verificar que PostgreSQL está activo
sudo systemctl status postgresql

# Verificar el puerto
sudo netstat -tlnp | grep 5432
# o
sudo lsof -i :5432
```

### Problema 2: "password authentication failed"

**Solución**: Credenciales incorrectas en `.env.local`
```bash
# Verificar usuario y contraseña
psql -U postgres -h localhost

# Si es necesario, cambiar la contraseña
psql -U postgres
ALTER USER postgres PASSWORD 'nueva_password';
```

### Problema 3: "database does not exist"

**Solución**: Crear la base de datos
```bash
psql -U postgres
CREATE DATABASE votes;
```

### Problema 4: En Mac con Docker Desktop

Si `host.docker.internal` no funciona, intenta con la IP de tu máquina:

```bash
# Obtener tu IP local
ifconfig | grep "inet " | grep -v 127.0.0.1

# Luego en docker-compose.local-db.yml, reemplaza:
DATABASE_HOST: 192.168.x.x  # Tu IP local
```

### Problema 5: Firewall bloqueando conexiones

```bash
# Linux - Permitir conexiones al puerto 5432
sudo ufw allow 5432/tcp

# Mac - Verificar firewall
# System Preferences > Security & Privacy > Firewall
```

## 🎛️ Configuración Avanzada

### Usar un puerto diferente de PostgreSQL

Si tu PostgreSQL local está en otro puerto (ej: 5433):

1. No necesitas cambiar nada en docker-compose (usa el puerto estándar 5432 del lado del cliente)
2. Asegúrate de que PostgreSQL esté escuchando en ese puerto

### Múltiples bases de datos

Puedes tener diferentes archivos `.env` para diferentes entornos:

```bash
.env.local          # PostgreSQL local
.env.dev            # PostgreSQL de desarrollo
.env.prod           # PostgreSQL de producción
```

Y usar:
```bash
docker compose -f docker-compose.local-db.yml --env-file .env.dev up -d
```

## 📊 Arquitectura

```
┌─────────────────────────────────────────────────┐
│          TU MÁQUINA LOCAL (HOST)                │
│                                                 │
│  ┌──────────────────┐                          │
│  │   PostgreSQL     │◄─────────────────┐       │
│  │   :5432          │                  │       │
│  └──────────────────┘                  │       │
│                                         │       │
│  ┌─────────────────────────────────────┼─────┐ │
│  │           DOCKER                    │     │ │
│  │                                     │     │ │
│  │  ┌──────────┐    ┌─────────┐      │     │ │
│  │  │   VOTE   │───▶│  REDIS  │      │     │ │
│  │  │  :5000   │    │  :6379  │      │     │ │
│  │  └────┬─────┘    └─────────┘      │     │ │
│  │       │                            │     │ │
│  │       │  host.docker.internal      │     │ │
│  │       └────────────────────────────┘     │ │
│  │                                           │ │
│  │  ┌──────────┐         ┌──────────┐       │ │
│  │  │  WORKER  │         │  RESULT  │       │ │
│  │  │  :3001   │         │  :5001   │       │ │
│  │  └────┬─────┘         └────┬─────┘       │ │
│  │       │                    │              │ │
│  │       └────────┬───────────┘              │ │
│  │                │                          │ │
│  │                └──host.docker.internal───┘ │
│  └──────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

## 🔄 Volver a usar PostgreSQL en Docker

Para volver al setup original con PostgreSQL en Docker:

```bash
# Detener los contenedores actuales
docker compose -f docker-compose.local-db.yml down

# Usar el docker-compose original
docker compose up -d
```

## 🛠️ Comandos Útiles

```bash
# Levantar con DB local
docker compose -f docker-compose.local-db.yml up -d

# Ver logs
docker compose -f docker-compose.local-db.yml logs -f

# Detener
docker compose -f docker-compose.local-db.yml down

# Conectarse a PostgreSQL local
psql -U postgres -d votes

# Ver votos en tiempo real
watch -n 1 'psql -U postgres -d votes -c "SELECT vote, COUNT(*) FROM votes GROUP BY vote;"'

# Limpiar votos
psql -U postgres -d votes -c "DELETE FROM votes;"
```

## 💡 Ventajas de este Setup

✅ Datos persisten fuera de Docker
✅ Más fácil hacer backups de la base de datos
✅ Puedes usar herramientas GUI (pgAdmin, DBeaver) sin configuración extra
✅ Mejor para desarrollo local
✅ Compartir datos entre múltiples proyectos
✅ No ocupas espacio en volúmenes de Docker

## ⚠️ Consideraciones

❗ La base de datos debe estar corriendo antes de levantar los contenedores
❗ Las credenciales deben estar correctamente configuradas
❗ El firewall debe permitir conexiones al puerto 5432
❗ `host.docker.internal` solo funciona en Docker Desktop (Mac/Windows)
   - En Linux, usa `172.17.0.1` o la IP del bridge de Docker

## 📚 Referencias

- [Docker host.docker.internal](https://docs.docker.com/desktop/networking/#i-want-to-connect-from-a-container-to-a-service-on-the-host)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Compose Networking](https://docs.docker.com/compose/networking/)

---

**Creado para**: ROXS DevOps Project 90
**Autor**: @roxsross
**Fecha**: 31 de octubre de 2025
