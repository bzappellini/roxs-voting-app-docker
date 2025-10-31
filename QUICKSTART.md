# 🚀 Inicio Rápido - ROXS Voting App

## ⚡ Levantar la aplicación en 3 pasos

### 1️⃣ Construir las imágenes

```bash
docker-compose build
```

### 2️⃣ Levantar los servicios

```bash
docker-compose up -d
```

### 3️⃣ Verificar que todo funciona

```bash
./verify.sh
```

O usa el Makefile:

```bash
make build && make up
```

## 🌐 Acceder a la aplicación

- **🗳️ Votar**: http://localhost:5000
- **📊 Ver Resultados**: http://localhost:5001

## 📋 Comandos rápidos con Makefile

```bash
make help          # Ver todos los comandos
make dev           # Levantar en modo desarrollo
make logs          # Ver logs en tiempo real
make health        # Verificar salud de servicios
make stats         # Ver estadísticas de votos
make down          # Detener servicios
make clean         # Limpiar todo
```

## 🔍 Ver logs de servicios individuales

```bash
docker-compose logs -f vote    # Logs del servicio de votación
docker-compose logs -f worker  # Logs del worker
docker-compose logs -f result  # Logs de resultados
```

## 🧪 Probar la aplicación

### Enviar un voto por terminal:

```bash
# Votar por gatos
curl -X POST http://localhost:5000/ -d "vote=a" -H "Content-Type: application/x-www-form-urlencoded"

# Votar por perros
curl -X POST http://localhost:5000/ -d "vote=b" -H "Content-Type: application/x-www-form-urlencoded"
```

### Ver estadísticas:

```bash
curl http://localhost:5000/stats | jq
```

## 🛑 Detener la aplicación

```bash
docker-compose down
```

Para eliminar también los volúmenes (datos):

```bash
docker-compose down -v
```

## 🐛 Troubleshooting

### Los servicios no inician:

```bash
# Ver logs de todos los servicios
docker-compose logs

# Ver estado de contenedores
docker-compose ps
```

### Reiniciar un servicio específico:

```bash
docker-compose restart vote
docker-compose restart worker
docker-compose restart result
```

### Reconstruir una imagen:

```bash
docker-compose up -d --build vote
```

### Acceder a la base de datos:

```bash
docker exec -it roxs-database psql -U postgres -d votes
```

Luego ejecuta:
```sql
SELECT vote, COUNT(*) FROM votes GROUP BY vote;
```

### Acceder a Redis:

```bash
docker exec -it roxs-redis redis-cli
```

Luego ejecuta:
```redis
LLEN votes
```

## 📊 Métricas de Prometheus

Todos los servicios exponen métricas:

- Vote: http://localhost:5000/metrics
- Worker: http://localhost:3001/metrics
- Result: http://localhost:5001/metrics

## 📚 Documentación completa

Ver [README-DOCKER.md](README-DOCKER.md) para la documentación completa.

## 🎯 Arquitectura

```
┌──────────┐    ┌─────────┐    ┌──────────┐
│   VOTE   │───▶│  REDIS  │◀───│  WORKER  │
│  :5000   │    │  :6379  │    │  :3001   │
└──────────┘    └─────────┘    └────┬─────┘
                                     │
                                     ▼
                              ┌──────────────┐
                              │  POSTGRESQL  │
                              │    :5432     │
                              └──────┬───────┘
                                     │
                                     ▼
                              ┌──────────────┐
                              │   RESULT     │
                              │    :5001     │
                              └──────────────┘
```

## 💡 Tips

- Usa `make help` para ver todos los comandos disponibles
- El script `verify.sh` es útil para CI/CD
- Los health checks están configurados en docker-compose
- Los datos persisten en volúmenes de Docker

## 🤘 ¡Disfruta aprendiendo DevOps con Roxs!

Para más información visita: [README.md](README.md)
