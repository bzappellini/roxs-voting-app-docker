# 🐘 PostgreSQL Standalone con Docker

## 📋 Descripción

Docker Compose minimalista para ejecutar **solo PostgreSQL** en un contenedor. Útil para:

- Desarrollo local sin instalar PostgreSQL
- Testing de aplicaciones
- Base de datos temporal
- Entorno de desarrollo aislado

## 🚀 Inicio Rápido

### 1. Configurar variables (opcional)

```bash
# Copiar archivo de ejemplo
cp .env.postgres.example .env.postgres

# Editar credenciales si es necesario
nano .env.postgres
```

### 2. Levantar PostgreSQL

```bash
# Opción 1: Con Makefile
make postgres-up

# Opción 2: Con docker compose directamente
docker compose -f docker-compose.postgres.yml up -d

# Opción 3: Con variables de entorno
docker compose -f docker-compose.postgres.yml --env-file .env.postgres up -d
```

### 3. Verificar que está corriendo

```bash
# Ver estado
docker ps | grep postgres-standalone

# Ver logs
docker compose -f docker-compose.postgres.yml logs -f

# Verificar salud
docker compose -f docker-compose.postgres.yml ps
```

## 🔌 Conectarse a PostgreSQL

### Desde tu máquina local

```bash
# Con psql (si lo tienes instalado)
psql -h localhost -p 5432 -U postgres -d votes

# Con docker exec
docker exec -it postgres-standalone psql -U postgres -d votes
```

### Desde tus aplicaciones

**Connection String:**
```
postgresql://postgres:postgres@localhost:5432/votes
```

**Configuración:**
```
Host: localhost
Port: 5432
User: postgres
Password: postgres
Database: votes
```

### Desde otros contenedores Docker

Si quieres conectar otros contenedores a este PostgreSQL:

```yaml
# En tu docker-compose de la aplicación
services:
  tu-app:
    # ... configuración de tu app
    networks:
      - postgres-network
    environment:
      DATABASE_HOST: postgres-standalone
      DATABASE_PORT: 5432

networks:
  postgres-network:
    external: true
    name: postgres-standalone-network
```

Luego modifica `docker-compose.postgres.yml` para agregar la red:

```yaml
services:
  database:
    # ... resto de la configuración
    networks:
      - postgres-network

networks:
  postgres-network:
    name: postgres-standalone-network
```

## 🗄️ Gestión de Datos

### Inicializar con scripts SQL

Los scripts en la carpeta `init-db/` se ejecutan automáticamente al crear el contenedor:

```bash
# Ya existe el archivo init-db/01-init.sql
# Puedes agregar más scripts:
echo "CREATE TABLE ejemplo (id SERIAL PRIMARY KEY);" > init-db/02-ejemplo.sql
```

### Backup de la base de datos

```bash
# Backup completo
docker exec postgres-standalone pg_dump -U postgres votes > backup_votes_$(date +%Y%m%d).sql

# Backup solo datos
docker exec postgres-standalone pg_dump -U postgres --data-only votes > backup_data_$(date +%Y%m%d).sql

# Backup solo esquema
docker exec postgres-standalone pg_dump -U postgres --schema-only votes > backup_schema_$(date +%Y%m%d).sql
```

### Restaurar backup

```bash
# Restaurar desde archivo
docker exec -i postgres-standalone psql -U postgres votes < backup_votes_20251031.sql

# O desde dentro del contenedor
cat backup_votes_20251031.sql | docker exec -i postgres-standalone psql -U postgres votes
```

### Limpiar datos

```bash
# Eliminar todos los votos
docker exec -it postgres-standalone psql -U postgres votes -c "DELETE FROM votes;"

# Resetear secuencias
docker exec -it postgres-standalone psql -U postgres votes -c "TRUNCATE votes RESTART IDENTITY CASCADE;"
```

## 🛠️ Comandos Útiles

### Gestión del contenedor

```bash
# Iniciar
make postgres-up
# o
docker compose -f docker-compose.postgres.yml up -d

# Detener
make postgres-down
# o
docker compose -f docker-compose.postgres.yml down

# Reiniciar
make postgres-restart
# o
docker compose -f docker-compose.postgres.yml restart

# Ver logs
make postgres-logs
# o
docker compose -f docker-compose.postgres.yml logs -f

# Ver estado
docker compose -f docker-compose.postgres.yml ps
```

### Acceso a PostgreSQL

```bash
# Shell interactivo de PostgreSQL
make postgres-shell
# o
docker exec -it postgres-standalone psql -U postgres -d votes

# Ejecutar comando SQL directamente
docker exec postgres-standalone psql -U postgres votes -c "SELECT * FROM votes;"

# Listar bases de datos
docker exec postgres-standalone psql -U postgres -c "\l"

# Listar tablas
docker exec postgres-standalone psql -U postgres votes -c "\dt"

# Describir tabla
docker exec postgres-standalone psql -U postgres votes -c "\d votes"
```

### Monitoreo

```bash
# Ver conexiones activas
docker exec postgres-standalone psql -U postgres -c "SELECT * FROM pg_stat_activity;"

# Ver tamaño de la base de datos
docker exec postgres-standalone psql -U postgres -c "SELECT pg_size_pretty(pg_database_size('votes'));"

# Ver tamaño de tablas
docker exec postgres-standalone psql -U postgres votes -c "SELECT tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size FROM pg_tables WHERE schemaname = 'public' ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;"
```

## 📊 Consultas SQL Útiles

```sql
-- Ver todos los votos
SELECT * FROM votes;

-- Contar votos por opción
SELECT vote, COUNT(*) as total 
FROM votes 
GROUP BY vote 
ORDER BY total DESC;

-- Ver últimos 10 votos
SELECT * FROM votes 
ORDER BY created_at DESC 
LIMIT 10;

-- Estadísticas generales
SELECT 
    COUNT(*) as total_votes,
    COUNT(DISTINCT id) as unique_voters,
    MIN(created_at) as first_vote,
    MAX(created_at) as last_vote
FROM votes;

-- Votos por día
SELECT 
    DATE(created_at) as date,
    COUNT(*) as votes
FROM votes
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

## 🔧 Configuración Avanzada

### Cambiar el puerto

Si el puerto 5432 está ocupado:

```bash
# En .env.postgres
POSTGRES_PORT=5433

# Luego conectarse:
psql -h localhost -p 5433 -U postgres -d votes
```

### Usar diferentes credenciales

```bash
# En .env.postgres
POSTGRES_USER=mi_usuario
POSTGRES_PASSWORD=mi_password_seguro
POSTGRES_DB=mi_base_datos
```

### Persistencia de datos

Los datos se guardan en un volumen Docker:

```bash
# Ver volumen
docker volume inspect postgres-standalone-data

# Ubicación del volumen
docker volume inspect postgres-standalone-data --format '{{ .Mountpoint }}'

# Eliminar volumen (¡CUIDADO! Se pierden todos los datos)
docker compose -f docker-compose.postgres.yml down -v
```

### Performance tuning

Puedes agregar configuraciones personalizadas creando un archivo `postgresql.conf`:

```bash
# Crear configuración personalizada
cat > postgres-custom.conf << EOF
max_connections = 200
shared_buffers = 256MB
work_mem = 8MB
maintenance_work_mem = 128MB
EOF
```

Luego modificar el docker-compose:

```yaml
volumes:
  - postgres-data:/var/lib/postgresql/data
  - ./postgres-custom.conf:/etc/postgresql/postgresql.conf
command: postgres -c config_file=/etc/postgresql/postgresql.conf
```

## 🐛 Troubleshooting

### Puerto ocupado

```bash
# Ver qué está usando el puerto 5432
sudo lsof -i :5432
# o
sudo netstat -tlnp | grep 5432

# Cambiar a otro puerto en .env.postgres
POSTGRES_PORT=5433
```

### No puedo conectarme

```bash
# Verificar que el contenedor está corriendo
docker ps | grep postgres

# Ver logs de errores
docker compose -f docker-compose.postgres.yml logs

# Verificar salud
docker compose -f docker-compose.postgres.yml ps
```

### Olvidé la contraseña

```bash
# Detener contenedor
docker compose -f docker-compose.postgres.yml down

# Cambiar contraseña en .env.postgres
POSTGRES_PASSWORD=nueva_password

# Eliminar volumen y recrear (¡Se pierden los datos!)
docker compose -f docker-compose.postgres.yml down -v
docker compose -f docker-compose.postgres.yml up -d
```

### Recuperar espacio

```bash
# Dentro de PostgreSQL
docker exec -it postgres-standalone psql -U postgres votes

# Ejecutar VACUUM
VACUUM FULL;
REINDEX DATABASE votes;
```

## 🔒 Seguridad

### Para producción:

1. **Cambiar contraseñas por defecto**
```bash
POSTGRES_PASSWORD=$(openssl rand -base64 32)
```

2. **Restringir acceso por red**
```yaml
ports:
  - "127.0.0.1:5432:5432"  # Solo localhost
```

3. **Usar secrets en lugar de variables de entorno**

4. **Configurar SSL/TLS**

5. **Regular backups automáticos**

## 📈 Integración con otras apps

### Con la aplicación ROXS Voting

```bash
# 1. Levantar solo PostgreSQL
make postgres-up

# 2. Conectar la app a este PostgreSQL
# Modificar docker-compose.local-db.yml para usar:
DATABASE_HOST: postgres-standalone

# 3. Asegurar que están en la misma red
docker network connect roxs-voting-network postgres-standalone
```

### Con pgAdmin

```bash
# Agregar pgAdmin al docker-compose.postgres.yml:
docker run -d \
  --name pgadmin \
  -p 5050:80 \
  -e PGADMIN_DEFAULT_EMAIL=admin@admin.com \
  -e PGADMIN_DEFAULT_PASSWORD=admin \
  --network postgres-standalone-network \
  dpage/pgadmin4
```

Acceder a: http://localhost:5050

## 🎯 Casos de Uso

### Desarrollo local
```bash
make postgres-up
# Desarrolla tu app apuntando a localhost:5432
```

### Testing automatizado
```bash
# En tus scripts de CI/CD
docker compose -f docker-compose.postgres.yml up -d
# Ejecutar tests
docker compose -f docker-compose.postgres.yml down -v
```

### Base de datos temporal
```bash
docker compose -f docker-compose.postgres.yml up -d
# Usar para pruebas
docker compose -f docker-compose.postgres.yml down -v  # Limpiar
```

## 📚 Recursos

- [PostgreSQL Docker Hub](https://hub.docker.com/_/postgres)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Compose Reference](https://docs.docker.com/compose/)

---

**Parte de**: ROXS DevOps Project 90  
**Autor**: @roxsross  
**Fecha**: 31 de octubre de 2025
