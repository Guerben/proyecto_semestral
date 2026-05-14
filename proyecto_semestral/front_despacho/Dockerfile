FROM node:18-alpine AS builder
# Etiqueta para identificar esta etapa de compilación
LABEL stage=builder
# Establecer directorio de trabajo
WORKDIR /app
# Copiar archivos de dependencias
COPY package*.json ./
# Instalar dependencias (todas, incluyendo devDependencies)
RUN npm ci
# Copiar código fuente de la aplicación
COPY . .
# Compilar la aplicación para producción usando Vite
RUN npm run build
FROM nginx:alpine
# Etiquetas de metadatos para documentar la imagen
LABEL maintainer="CITT"
LABEL description="Frontend React - Servicio de Despachos (Vite + Nginx)"
LABEL version="1.0.0"
# Instalar curl para healthcheck
RUN apk add --no-cache curl
# Eliminar configuración por defecto de nginx
RUN rm -rf /usr/share/nginx/html/*
# Copiar archivos compilados desde la etapa de build
COPY --from=builder /app/dist /usr/share/nginx/html
# Nginx: SPA + proxy a APIs (solo el puerto 80 del frontend debe publicarse)
COPY nginx.default.conf /etc/nginx/conf.d/default.conf
# Cambiar permisos para que nginx pueda acceder a los archivos
RUN chown -R nginx:nginx /usr/share/nginx/html
# Puerto en el que nginx escucha peticiones HTTP
EXPOSE 80
# Health check para verificar que nginx esté activo y respondiendo
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/health || exit 1
# Usuario no-root para seguridad del contenedor
USER nginx
# Comando de inicio - ejecutar nginx en foreground para logs en Docker
CMD ["nginx", "-g", "daemon off;"]