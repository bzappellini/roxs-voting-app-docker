# 🐳 Guía de Docker - ROXS Voting App

## 📋 Descripción de la Arquitectura

Esta aplicación de votación está compuesta por 5 servicios principales:

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│    VOTE     │         │   WORKER    │         │   RESULT    │
│  (Python)   │         │  (Node.js)  │         │  (Node.js)  │
│   :5000     │         │   :3001     │         │   :5001     │
└──────┬──────┘         └──────┬──────┘         └──────┬──────┘
       │                       │                        │
       │ Publica votos        │ Consume votos         │ Lee resultados
       │                       │                        │
       ▼                       ▼                        ▼
┌─────────────┐         ┌──────────────────────────────────┐
│    REDIS    │         │          POSTGRESQL              │
│   :6379     │◄────────┤           :5432                  │
└─────────────┘         └──────────────────────────────────┘
```

### Servicios

1. **Vote** (Puerto 5000) - Frontend de votación en Flask/Python
2. **Worker** (Puerto 3001) - Procesador de votos en Node.js
3. **Result** (Puerto 5001) - Visualización de resultados en tiempo real
4. **Redis** (Puerto 6379) - Cola de mensajes
5. **PostgreSQL** (Puerto 5432) - Base de datos persistente

## 🚀 Inicio Rápido

### Prerrequisitos

- Docker 20.10+
- Docker Compose 2.0+
- make (opcional, para usar el Makefile)

### Levantar la aplicación

```bash
# Opción 1: Usando Docker Compose directamente
docker-compose up -d

# Opción 2: Usando Makefile
make up

# Opción 3: Modo desarrollo (con logs en tiempo real)
make dev
```

### Acceder a los servicios

- **Vote App**: http://localhost:5000
- **Result App**: http://localhost:5001
- **Worker Metrics**: http://localhost:3001/metrics
- **Vote Metrics**: http://localhost:5000/metrics
- **Result Metrics**: http://localhost:5001/metrics

## 🛠️ Comandos Útiles

### Usando Makefile

```bash
make help           # Ver todos los comandos disponibles
make build          # Construir las imágenes
make up             # Levantar servicios
make down           # Detener servicios
make logs           # Ver logs de todos los servicios
make logs-vote      # Ver logs solo del servicio vote
make ps             # Ver estado de contenedores
make health         # Verificar salud de servicios
make stats          # Ver estadísticas de votos
make clean          # Limpiar contenedores y volúmenes
```

### Usando Docker Compose

```bash
# Construir imágenes
docker-compose build

# Levantar servicios
docker-compose up -d

# Ver logs
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f vote

# Detener servicios
docker-compose down

# Limpiar todo (incluye volúmenes)
docker-compose down -v
```

## 📊 Monitoreo y Métricas

Todos los servicios exponen métricas de Prometheus:

```bash
# Ver métricas del servicio vote
curl http://localhost:5000/metrics

# Ver métricas del worker
curl http://localhost:3001/metrics

# Ver métricas del result
curl http://localhost:5001/metrics

# O usando Makefile
make metrics-vote
make metrics-worker
make metrics-result
```

### Health Checks

```bash
# Verificar salud de todos los servicios
make health

# O manualmente
curl http://localhost:5000/healthz
curl http://localhost:3001/healthz
curl http://localhost:5001/healthz
```

## 🧪 Testing

### Enviar votos de prueba

```bash
# Votar por gatos (opción a)
curl -X POST http://localhost:5000/ -d "vote=a" -H "Content-Type: application/x-www-form-urlencoded"

# Votar por perros (opción b)
curl -X POST http://localhost:5000/ -d "vote=b" -H "Content-Type: application/x-www-form-urlencoded"

# O usando Makefile
make test-vote
```

### Ver estadísticas

```bash
# Ver estadísticas actuales
curl http://localhost:5000/stats | jq .

# O usando Makefile
make stats
```

## 🔧 Troubleshooting

### Ver logs de un servicio específico

```bash
make logs-vote
make logs-worker
make logs-result

# O con docker-compose
docker-compose logs -f vote
```

### Acceder al shell de un contenedor

```bash
make shell-vote      # Acceder al contenedor vote
make shell-worker    # Acceder al contenedor worker
make shell-result    # Acceder al contenedor result
make shell-db        # Acceder a PostgreSQL
make shell-redis     # Acceder a Redis CLI
```

### Reconstruir un servicio específico

```bash
# Reconstruir solo el servicio vote
make rebuild service=vote

# Reconstruir solo el worker
make rebuild service=worker
```

### Escalar workers

```bash
# Levantar 3 instancias del worker
make scale-worker n=3
```

### Reiniciar servicios

```bash
make restart

# O manualmente
docker-compose restart
```

## 🗄️ Persistencia de Datos

Los datos se guardan en volúmenes de Docker:

- `roxs-redis-data` - Datos de Redis
- `roxs-db-data` - Datos de PostgreSQL

Para eliminar los volúmenes y empezar desde cero:

```bash
make clean
```

## 🌐 Variables de Entorno

Las siguientes variables están configuradas en el `docker-compose.yml`:

### Vote Service
```
REDIS_HOST=redis
DATABASE_HOST=database
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres
DATABASE_NAME=votes
OPTION_A="Cats"
OPTION_B="Dogs"
```

### Worker Service
```
REDIS_HOST=redis
DATABASE_HOST=database
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres
DATABASE_NAME=votes
```

### Result Service
```
DATABASE_HOST=database
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres
DATABASE_NAME=votes
APP_PORT=3000
```

## 📦 Estructura de Dockerfiles

### Vote (Python/Flask)
- Base: `python:3.13-slim`
- Puerto: 80
- Servidor: Gunicorn con 4 workers

### Worker (Node.js)
- Base: `node:20-slim`
- Puerto: 3000 (métricas)
- Proceso: Node.js

### Result (Node.js)
- Base: `node:20-slim`
- Puerto: 3000
- Proceso: Node.js con Socket.IO

## 🔒 Seguridad

### Mejoras recomendadas para producción:

1. **Variables de entorno**: Usar un archivo `.env` o secrets
2. **Contraseñas**: Cambiar las contraseñas por defecto
3. **Network isolation**: Configurar redes internas
4. **Resource limits**: Agregar límites de CPU/Memoria
5. **Non-root users**: Ejecutar contenedores sin privilegios

## 📈 Optimizaciones

### Build multi-stage

Para producción, considera usar builds multi-stage para reducir el tamaño de las imágenes:

```dockerfile
# Ejemplo para Node.js
FROM node:20-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:20-slim
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
CMD ["node", "main.js"]
```

## 🐛 Problemas Comunes

### Los servicios no pueden conectarse

```bash
# Verificar que todos los servicios estén en la misma red
docker network ls
docker network inspect roxs-voting-network
```

### El worker no procesa votos

```bash
# Verificar conexiones
make logs-worker

# Verificar Redis
make shell-redis
> LLEN votes
```

### La base de datos no tiene votos

```bash
# Acceder a PostgreSQL
make shell-db
> SELECT * FROM votes;
```

## 📚 Recursos Adicionales

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Best Practices for Writing Dockerfiles](https://docs.docker.com/develop/dev-best-practices/)

## 🤝 Contribuir

Este proyecto es parte del desafío **90 Días de DevOps con Roxs**. 

¡Diviértete aprendiendo Docker! 🚀
