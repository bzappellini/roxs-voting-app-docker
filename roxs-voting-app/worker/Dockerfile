# Dockerfile para Worker (Node.js)
FROM node:20-slim

# Establecer el directorio de trabajo
WORKDIR /app

# Copiar package.json
COPY package.json ./

# Instalar dependencias
RUN npm install --omit=dev

# Copiar el código de la aplicación
COPY . .

# Exponer puerto para métricas
EXPOSE 3000

# Variables de entorno por defecto
ENV REDIS_HOST=redis
ENV DATABASE_HOST=database
ENV DATABASE_USER=postgres
ENV DATABASE_PASSWORD=postgres
ENV DATABASE_NAME=votes
ENV NODE_ENV=production

# Comando para ejecutar el worker
CMD ["node", "main.js"]
