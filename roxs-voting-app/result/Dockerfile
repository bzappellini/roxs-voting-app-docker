# Dockerfile para Result App (Node.js)
FROM node:20-slim

# Establecer el directorio de trabajo
WORKDIR /app

# Copiar package.json
COPY package.json ./

# Instalar dependencias
RUN npm install --omit=dev

# Copiar el código de la aplicación
COPY . .

# Exponer el puerto de la aplicación
EXPOSE 3000

# Variables de entorno por defecto
ENV DATABASE_HOST=database
ENV DATABASE_USER=postgres
ENV DATABASE_PASSWORD=postgres
ENV DATABASE_NAME=votes
ENV APP_PORT=3000
ENV NODE_ENV=production

# Comando para ejecutar la aplicación
CMD ["node", "main.js"]
