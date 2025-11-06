# 🔌 Guía de Conexión a PostgreSQL Externo

## 📋 Descripción

Este docker-compose alternativo (`docker-compose.local-db.yml`) permite que los contenedores de la aplicación se conecten a una base de datos PostgreSQL que está corriendo en un **contenedor separado** (usando `docker-compose.postgres.yml`).

Esta arquitectura de **múltiples docker-compose** permite:
- Gestionar la base de datos independientemente de la aplicación
- Reiniciar servicios de aplicación sin afectar la base de datos
- Compartir una misma base de datos entre múltiples aplicaciones
- Simular un entorno donde la base de datos está en otro servidor

## 🎯 Casos de Uso

- Separar la capa de datos de la capa de aplicación
- Desarrollo con base de datos compartida entre proyectos
- Simular arquitectura de microservicios
- Mantener datos persistentes independientes de la aplicación
- Testing con base de datos aislada

## ⚙️ Requisitos Previos

### 1. PostgreSQL debe estar corriendo en un contenedor separado

Usar el docker-compose dedicado para PostgreSQL:

```bash
# Verificar que PostgreSQL está corriendo
docker ps | grep postgres-standalone

# O levantar PostgreSQL si no está corriendo
docker compose -f docker-compose.postgres.yml up -d

# Verificar salud del contenedor
docker compose -f docker-compose.postgres.yml ps
```

### 2. Los contenedores deben poder comunicarse

Ambos docker-compose usan la red bridge de Docker por defecto. Los contenedores pueden comunicarse entre sí usando:
- `host.docker.internal` - Apunta al host de Docker (funciona en Mac/Windows)
- `172.17.0.1` - IP del bridge de Docker (alternativa en Linux)
- Nombre del contenedor si están en la misma red custom

### 3. No hay configuración adicional necesaria

A diferencia de PostgreSQL instalado localmente, el setup con contenedores separados funciona **out-of-the-box** sin configurar archivos de sistema.

## 🚀 Pasos de Configuración

### 1. Levantar PostgreSQL en contenedor separado

```bash
# Opción 1: Con Makefile
make postgres-up

# Opción 2: Con docker compose
docker compose -f docker-compose.postgres.yml up -d

# Verificar que está corriendo
docker ps | grep postgres-standalone
```

La base de datos y tabla se crean automáticamente gracias al script `init-db/01-init.sql` que se ejecuta al iniciar el contenedor por primera vez.

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

### 3. Levantar los servicios de la aplicación

```bash
# Usando el docker-compose específico
docker compose -f docker-compose.local-db.yml --env-file .env.local up -d

# O con Makefile personalizado
make up-local

# Verificar que todos los servicios están corriendo
docker ps
```

Deberías ver:
- `postgres-standalone` - Base de datos PostgreSQL
- `roxs-vote` - Aplicación de votación
- `roxs-worker` - Procesador de votos
- `roxs-result` - Visualización de resultados
- `roxs-redis` - Cache y cola de mensajes

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

### 3. Verificar datos en PostgreSQL (contenedor separado)

```bash
# Conectarse al contenedor de PostgreSQL
docker exec -it postgres-standalone psql -U postgres -d votes

# Ver votos
SELECT * FROM votes;

# Ver estadísticas
SELECT vote, COUNT(*) FROM votes GROUP BY vote;

# Salir
\q

# O ejecutar consultas directamente
docker exec postgres-standalone psql -U postgres votes -c "SELECT vote, COUNT(*) FROM votes GROUP BY vote;"
```

## 🔧 Troubleshooting

### Problema 1: "Connection refused"

**Solución**: El contenedor de PostgreSQL no está corriendo
```bash
# Verificar contenedores activos
docker ps | grep postgres-standalone

# Si no está corriendo, levantarlo
docker compose -f docker-compose.postgres.yml up -d

# Ver logs si hay problemas
docker compose -f docker-compose.postgres.yml logs -f
```

### Problema 2: "password authentication failed"

**Solución**: Credenciales incorrectas en `.env.local`
```bash
# Verificar las credenciales configuradas
cat .env.local

# Asegúrate de que coincidan con las del contenedor postgres
# Por defecto: postgres/postgres
```

### Problema 3: "database does not exist"

**Solución**: La base de datos no se inicializó correctamente
```bash
# Recrear el contenedor de PostgreSQL (se pierden los datos)
docker compose -f docker-compose.postgres.yml down -v
docker compose -f docker-compose.postgres.yml up -d

# El script init-db/01-init.sql se ejecutará automáticamente
```

### Problema 4: Los contenedores no se comunican

**Solución**: Verificar que `host.docker.internal` funciona

```bash
# En Linux, si host.docker.internal no funciona, puedes:
# 1. Usar la IP del bridge de Docker
docker network inspect bridge | grep Gateway
# Usa esa IP en lugar de host.docker.internal

# 2. O crear una red compartida (mejor opción)
# Ver sección "Configuración Avanzada" más abajo
```

### Problema 5: "Orphan containers" warning

**Solución**: Este warning es normal cuando ejecutas múltiples docker-compose
```bash
# Es solo una advertencia, puedes ignorarla
# O agregar --remove-orphans si quieres limpiarlo
docker compose -f docker-compose.local-db.yml up -d --remove-orphans
```

## 🎛️ Configuración Avanzada

### Usar una red compartida (Recomendado para producción)

Para mejor comunicación entre contenedores, puedes crear una red compartida:

```bash
# Crear red compartida
docker network create roxs-shared-network

# Conectar PostgreSQL a la red
docker network connect roxs-shared-network postgres-standalone

# Modificar docker-compose.local-db.yml para usar el nombre del contenedor:
# DATABASE_HOST: postgres-standalone  (en lugar de host.docker.internal)
```

### Escalar servicios independientemente

```bash
# Escalar solo workers
docker compose -f docker-compose.local-db.yml up -d --scale worker=3

# Reiniciar solo la aplicación sin tocar la DB
docker compose -f docker-compose.local-db.yml restart

# Actualizar solo PostgreSQL
docker compose -f docker-compose.postgres.yml restart
```

### Múltiples entornos

Puedes tener diferentes archivos `.env` para diferentes entornos:

```bash
.env.local          # Desarrollo local
.env.dev            # Desarrollo
.env.staging        # Staging
.env.prod           # Producción
```

Y usar:
```bash
docker compose -f docker-compose.local-db.yml --env-file .env.dev up -d
```

## 📊 Arquitectura - Múltiples Docker Compose

```
┌───────────────────────────────────────────────────────────────┐
│                    DOCKER HOST                                │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  docker-compose.postgres.yml                           │  │
│  │                                                         │  │
│  │  ┌──────────────────────────────────────┐              │  │
│  │  │  POSTGRES-STANDALONE                 │              │  │
│  │  │  :5432 (expuesto al host)            │              │  │
│  │  │  Volume: postgres-standalone-data    │              │  │
│  │  └──────────────┬───────────────────────┘              │  │
│  └─────────────────┼──────────────────────────────────────┘  │
│                    │                                          │
│                    │ host.docker.internal                     │
│                    │ (172.17.0.1 en Linux)                    │
│                    │                                          │
│  ┌─────────────────┼──────────────────────────────────────┐  │
│  │  docker-compose.local-db.yml          │               │  │
│  │                                        ▼               │  │
│  │  ┌──────────┐    ┌─────────┐    Conexión a DB         │  │
│  │  │   VOTE   │───▶│  REDIS  │    externa               │  │
│  │  │  :5000   │    │  :6379  │                          │  │
│  │  └────┬─────┘    └─────────┘                          │  │
│  │       │                                                │  │
│  │       │  Publica votos en Redis                       │  │
│  │       │                                                │  │
│  │  ┌────▼─────┐         ┌──────────┐                    │  │
│  │  │  WORKER  │────────▶│  RESULT  │                    │  │
│  │  │  :3001   │         │  :5001   │                    │  │
│  │  └────┬─────┘         └────┬─────┘                    │  │
│  │       │                    │                           │  │
│  │       └────────┬───────────┘                           │  │
│  │                │                                       │  │
│  │                └── Leen de PostgreSQL externo          │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Flujo de datos:
1. Usuario vota en VOTE (:5000)
2. VOTE publica en REDIS
3. WORKER consume de REDIS → escribe en POSTGRES (externo)
4. RESULT lee de POSTGRES (externo) → muestra en tiempo real
```

## 🔄 Cambiar entre configuraciones

### Setup actual (PostgreSQL separado):
```bash
# Terminal 1: PostgreSQL
docker compose -f docker-compose.postgres.yml up -d

# Terminal 2: Aplicación
docker compose -f docker-compose.local-db.yml up -d
```

### Volver al setup todo-en-uno:
```bash
# Detener ambos docker-compose
docker compose -f docker-compose.local-db.yml down
docker compose -f docker-compose.postgres.yml down

# Usar el docker-compose original (todo integrado)
docker compose up -d
```

## 🛠️ Comandos Útiles

### Gestión de servicios:
```bash
# Levantar PostgreSQL (primero)
make postgres-up
# o
docker compose -f docker-compose.postgres.yml up -d

# Levantar aplicación (después)
make up-local
# o
docker compose -f docker-compose.local-db.yml up -d

# Ver logs de la aplicación
docker compose -f docker-compose.local-db.yml logs -f

# Ver logs de PostgreSQL
docker compose -f docker-compose.postgres.yml logs -f

# Ver todos los contenedores
docker ps

# Detener aplicación (sin afectar DB)
docker compose -f docker-compose.local-db.yml down

# Detener todo
docker compose -f docker-compose.local-db.yml down
docker compose -f docker-compose.postgres.yml down
```

### Acceso a PostgreSQL:
```bash
# Conectarse al contenedor de PostgreSQL
make postgres-shell
# o
docker exec -it postgres-standalone psql -U postgres -d votes

# Ver votos en tiempo real
watch -n 1 'docker exec postgres-standalone psql -U postgres votes -c "SELECT vote, COUNT(*) FROM votes GROUP BY vote;"'

# Limpiar votos
docker exec postgres-standalone psql -U postgres votes -c "DELETE FROM votes;"
```

## 💡 Ventajas de este Setup (Múltiples Docker Compose)

✅ **Separación de responsabilidades** - Base de datos independiente de la aplicación
✅ **Datos persistentes** - PostgreSQL puede reiniciarse sin afectar la app
✅ **Desarrollo flexible** - Reinicia la app sin tocar la DB
✅ **Simula microservicios** - Arquitectura más realista
✅ **Fácil de escalar** - Cada servicio se gestiona por separado
✅ **Testing aislado** - Prueba componentes independientemente
✅ **Compartir DB** - Múltiples aplicaciones pueden usar la misma DB

## ⚠️ Consideraciones

❗ **Orden de inicio**: PostgreSQL debe levantarse ANTES que la aplicación
❗ **Credenciales**: Deben coincidir entre `.env.local` y `.env.postgres`
❗ **Comunicación**: Usar `host.docker.internal` (Mac/Windows) o `172.17.0.1` (Linux)
❗ **Orphan warnings**: Son normales con múltiples docker-compose, se pueden ignorar
❗ **Volúmenes**: Cada docker-compose tiene sus propios volúmenes
❗ **Redes**: Por defecto usan bridge, considera usar una red compartida en producción

## 📚 Referencias

- [Docker host.docker.internal](https://docs.docker.com/desktop/networking/#i-want-to-connect-from-a-container-to-a-service-on-the-host)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Compose Networking](https://docs.docker.com/compose/networking/)

## 🎓 Resumen del Flujo de Trabajo

1. **Iniciar PostgreSQL** (contenedor separado):
   ```bash
   make postgres-up
   ```

2. **Iniciar aplicación** (conecta a PostgreSQL externo):
   ```bash
   make up-local
   ```

3. **Verificar** que todo funciona:
   ```bash
   docker ps
   curl http://localhost:5000/healthz
   ```

4. **Desarrollar** con confianza:
   - Reinicia la app sin perder datos
   - PostgreSQL corre independiente
   - Simula arquitectura de microservicios

5. **Limpiar** cuando termines:
   ```bash
   make down-local          # Detiene app
   make postgres-down       # Detiene PostgreSQL
   ```

---

**Creado para**: ROXS DevOps Project 90  
**Autor**: @roxsross  
**Actualizado**: 6 de noviembre de 2025  
**Arquitectura**: Múltiples Docker Compose (PostgreSQL separado)
