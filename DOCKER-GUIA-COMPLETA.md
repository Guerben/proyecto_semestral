# ============================================================================
# GUÍA COMPLETA - Docker, Docker Compose y CI/CD
# ============================================================================

## 📋 Tabla de Contenidos
1. [Estructura del Proyecto](#estructura-del-proyecto)
2. [Requisitos Previos](#requisitos-previos)
3. [Construcción Local](#construcción-local)
4. [Ejecución con Docker Compose](#ejecución-con-docker-compose)
5. [Publicación en Registros](#publicación-en-registros)
6. [Pipeline CI/CD en GitHub Actions](#pipeline-cicd-en-github-actions)
7. [Buenas Prácticas de Seguridad](#buenas-prácticas-de-seguridad)
8. [Troubleshooting](#troubleshooting)
9. [Despliegue en EC2 con S3 + Docker (guía detallada)](DEPLOY-EC2.md)

---

## 🏗️ Estructura del Proyecto

```
proyecto-semestral/
├── docker-compose.yml                    # Orquestación local (build en máquina)
├── docker-compose.prod.yml               # EC2/producción (solo imágenes del registro)
├── DEPLOY-EC2.md                         # Paso a paso despliegue AWS EC2 + GitHub Actions
├── .env.example                          # Plantilla de variables de entorno
├── proyecto semestral/
│   ├── back-Ventas_SpringBoot/
│   │   └── Springboot-API-REST/
│   │       ├── Dockerfile                # API Ventas (Java)
│   │       ├── pom.xml
│   │       └── src/
│   ├── back-Despachos_SpringBoot/
│   │   └── Springboot-API-REST-DESPACHO/
│   │       ├── Dockerfile                # API Despachos (Java)
│   │       ├── pom.xml
│   │       └── src/
│   └── front_despacho/
│       ├── Dockerfile                    # Frontend React
│       ├── nginx.conf                    # Configuración de Nginx
│       ├── package.json
│       └── src/
└── .github/
    └── workflows/
        ├── build-api-ventas.yml          # Pipeline CI/CD Ventas
        ├── build-api-despachos.yml       # Pipeline CI/CD Despachos
        ├── build-frontend.yml            # Pipeline CI/CD Frontend
        └── deploy-ec2.yml                # Despliegue remoto vía SSH a EC2
```

---

## 🔧 Requisitos Previos

### Local Development
```bash
# Requisitos mínimos:
- Docker 20.10+ (con Buildx para multi-stage builds)
- Docker Compose 2.0+
- Git 2.25+
- Maven 3.8+ (opcional, incluido en Dockerfile)
- Node.js 18+ (opcional, incluido en Dockerfile)
```

### Verificar instalación:
```bash
docker --version          # Docker 20.10.0+
docker-compose --version  # Docker Compose 2.0.0+
docker buildx version     # BuildKit habilitado
```

---

## 🐳 Construcción Local

### 1. Clonar el repositorio
```bash
git clone <tu-repositorio>
cd ISY1101_EP2_Proyecto\ Semestral
```

### 2. Crear archivo .env desde template
```bash
cp .env.example .env

# Editar .env con tus valores (opcional, los valores por defecto funcionan)
```

### 3. Construir imagen de API Ventas
```bash
cd proyecto\ semestral/back-Ventas_SpringBoot/Springboot-API-REST

# Build simple
docker build -t api-ventas:latest .

# Build con argumentos adicionales
docker build \
  --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  --build-arg VCS_REF=$(git rev-parse --short HEAD) \
  -t api-ventas:1.0.0 \
  .

# Build multiplataforma (requiere Buildx)
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag api-ventas:latest \
  --load \
  .
```

### 4. Construir imagen de API Despachos
```bash
cd proyecto\ semestral/back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO

docker build -t api-despachos:latest .
```

### 5. Construir imagen de Frontend
```bash
cd proyecto\ semestral/front_despacho

docker build -t frontend:latest .
```

### 6. Verificar imágenes construidas
```bash
docker images | grep -E "api-ventas|api-despachos|frontend"

# Output esperado:
# REPOSITORY      TAG      IMAGE ID        CREATED         SIZE
# frontend        latest   abc123def456    2 seconds ago    145MB
# api-despachos   latest   def456ghi789    5 seconds ago    312MB
# api-ventas      latest   ghi789jkl012    10 seconds ago   312MB
```

---

## 🚀 Ejecución con Docker Compose

### 1. Levantar todos los servicios
```bash
# Asegúrate de estar en el directorio raíz del proyecto
cd ISY1101_EP2_Proyecto\ Semestral

# Ejecutar con .env
docker-compose up -d

# Verbose (para ver logs en tiempo real)
docker-compose up

# Reconstruir imágenes si hubo cambios
docker-compose up --build -d
```

### 2. Verificar servicios
```bash
# Ver estado de todos los contenedores
docker-compose ps

# Ver logs de un servicio específico
docker-compose logs api-ventas -f        # -f = follow (tiempo real)
docker-compose logs api-despachos -f
docker-compose logs frontend -f
docker-compose logs db -f

# Ver logs de todos los servicios
docker-compose logs -f
```

### 3. Acceder a los servicios
```bash
# Frontend React
http://localhost:3000

# API Ventas
http://localhost:8080/swagger-ui.html        # Swagger UI
http://localhost:8080/actuator/health        # Health check

# API Despachos
http://localhost:8081/swagger-ui.html        # Swagger UI
http://localhost:8081/actuator/health        # Health check

# Base de datos MySQL
localhost:3306
username: appuser
password: appuser123
database: proyecto_db
```

### 4. Ejecutar comandos en contenedores
```bash
# Acceder al shell de un contenedor
docker-compose exec api-ventas bash
docker-compose exec api-despachos bash
docker-compose exec frontend sh

# Ejecutar comando específico
docker-compose exec db mysql -u appuser -pappuser123 -e "SHOW TABLES;"
docker-compose exec api-ventas mvn clean test

# Ver logs desde el contenedor
docker-compose exec frontend tail -f /var/log/nginx/access.log
```

### 5. Detener servicios
```bash
# Parar pero conservar volúmenes (datos persisten)
docker-compose stop

# Parar y eliminar contenedores (datos persisten en volúmenes)
docker-compose down

# Parar, eliminar contenedores Y volúmenes (CUIDADO: pierde datos)
docker-compose down -v

# Resetear completamente (eliminar todo)
docker-compose down -v --remove-orphans
```

### 6. Actualizar variables de entorno
```bash
# Modificar .env y aplicar cambios
nano .env
docker-compose up -d --force-recreate

# O especificar variables en línea de comando
VENTAS_PORT=9000 DB_PASSWORD=nuevapass docker-compose up -d
```

---

## 📦 Publicación en Registros

### Docker Hub

#### 1. Preparar credenciales
```bash
# Crear token en Docker Hub
# Settings > Security > New Access Token

# Guardar credenciales (local)
docker login

# O exportar credenciales
echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
```

#### 2. Taggear imágenes
```bash
# Con tu usuario de Docker Hub (reemplazar "tu-usuario")
docker tag api-ventas:latest tu-usuario/api-ventas:1.0.0
docker tag api-ventas:latest tu-usuario/api-ventas:latest

docker tag api-despachos:latest tu-usuario/api-despachos:1.0.0
docker tag api-despachos:latest tu-usuario/api-despachos:latest

docker tag frontend:latest tu-usuario/frontend:1.0.0
docker tag frontend:latest tu-usuario/frontend:latest
```

#### 3. Publicar imágenes
```bash
# Push individual
docker push tu-usuario/api-ventas:1.0.0
docker push tu-usuario/api-ventas:latest

# O push todas
docker push tu-usuario/api-despachos:1.0.0
docker push tu-usuario/api-despachos:latest
docker push tu-usuario/frontend:1.0.0
docker push tu-usuario/frontend:latest
```

---

## 🔄 Pipeline CI/CD en GitHub Actions

Para **desplegar en EC2 sin Docker Hub** (código en **Amazon S3**, build en el servidor con Docker Compose), sigue la guía detallada en **[DEPLOY-EC2.md](DEPLOY-EC2.md)** (bucket, IAM, Security Group, `.env` fuera del sync, subida manual o workflow **Deploy to EC2 (S3 + build en servidor)**). Si más adelante usas imágenes en un registro, consulta el anexo de ese mismo archivo y `docker-compose.prod.yml`.

### 1. Configurar secretos en GitHub

**Settings > Secrets and variables > Actions**

Agregar estos secretos:

```
DOCKER_HUB_USERNAME        # Tu usuario de Docker Hub
DOCKER_HUB_TOKEN           # Token de Docker Hub (Settings > Security)
```

### 2. Cómo obtener Docker Hub Token

1. Ir a https://hub.docker.com/settings/security
2. Clic en "New Access Token"
3. Nombre: "GitHub Actions"
4. Permisos: Read & Write
5. Generar y copiar el token
6. Agregar a GitHub Secrets como `DOCKER_HUB_TOKEN`

### 3. Triggersde los Workflows

Los workflows se ejecutan automáticamente cuando:

```yaml
# Cambios en rama main o develop
push:
  branches:
    - main
    - develop
  paths:
    - 'proyecto semestral/back-Ventas_SpringBoot/**'
    - '.github/workflows/build-api-ventas.yml'

# O manualmente desde GitHub UI
workflow_dispatch
```

### 4. Monitorear workflows

```bash
# Ver estado en GitHub
https://github.com/tu-usuario/repo/actions

# Ver logs de ejecución
https://github.com/tu-usuario/repo/actions/runs/<RUN_ID>
```

### 5. Matriz de construcción (opcional)

Para construir en múltiples plataformas:

```yaml
strategy:
  matrix:
    platform: [linux/amd64, linux/arm64]
    node-version: [18, 20]
```

---

## 🔒 Buenas Prácticas de Seguridad

### 1. Imágenes Base Seguras

✅ **Usar imágenes officialesminimales**
```dockerfile
FROM eclipse-temurin:17-jre-alpine    # Java optimizado
FROM node:18-alpine                    # Node.js mínimo
FROM nginx:alpine                      # Nginx ligero
```

❌ **Evitar**
```dockerfile
FROM ubuntu:latest                     # Demasiado grande, vulnerabilidades
FROM java:latest                       # Imagen oficial deprecada
```

### 2. Usuario No-Root

✅ **Ejecutar con usuario sin permisos**
```dockerfile
RUN adduser -D -u 1001 -G appgroup appuser
USER appuser
```

❌ **Evitar**
```dockerfile
# No especificar USER = ejecuta como root (PELIGRO)
```

### 3. Multi-stage Builds

✅ **Reducir tamaño final**
```dockerfile
FROM maven:3.9 AS builder
# ... compile ...

FROM eclipse-temurin:17-jre-alpine
COPY --from=builder /app/target/*.jar app.jar
```

❌ **Evitar**
```dockerfile
FROM maven:3.9
# ... compile + runtime en la misma imagen
# Tamaño: 1GB+
```

### 4. Health Checks

✅ **Verificar que la app está activa**
```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -q -O - http://localhost:8080/actuator/health
```

### 5. Limites de Recursos

✅ **En docker-compose.yml**
```yaml
deploy:
  resources:
    limits:
      cpus: '1'
      memory: 512M
    reservations:
      cpus: '0.5'
      memory: 256M
```

### 6. Variables de Entorno Sensitivas

❌ **NO hardcodear credenciales**
```dockerfile
# ¡NUNCA!
ENV DB_PASSWORD=admin123
```

✅ **Usar .env o secrets**
```bash
docker-compose up --env-file .env
# o en CI/CD:
docker run -e DB_PASSWORD="${{ secrets.DB_PASSWORD }}" ...
```

### 7. Escaneo de Vulnerabilidades

✅ **Usar Trivy en CI/CD**
```yaml
- name: Security scan
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ image }}
    format: 'sarif'
    severity: 'CRITICAL,HIGH'
```

### 8. No Copyar Archivos Innecesarios

✅ **Usar .dockerignore**
```
node_modules/
.git/
.env
dist/
build/
__pycache__/
*.class
```

❌ **Evitar**
```dockerfile
COPY . .    # Copia TODO, incluyendo .git, node_modules, etc.
```

---

## 🐛 Troubleshooting

### Puerto ya en uso
```bash
# Encontrar qué proceso usa el puerto
lsof -i :8080
netstat -tulpn | grep 8080

# Liberar puerto
kill -9 <PID>

# O usar puerto diferente
VENTAS_PORT=9000 docker-compose up -d
```

### Base de datos no inicializa
```bash
# Verificar logs de MySQL
docker-compose logs db

# Reiniciar BD
docker-compose down db
docker volume rm proyecto_semestral_mysql-data
docker-compose up db -d

# Conectar directamente
docker-compose exec db mysql -u appuser -p
```

### API no conecta a BD
```bash
# Verificar nombre del host (debe ser "db")
docker-compose exec api-ventas cat /etc/hosts

# Verificar conectividad
docker-compose exec api-ventas ping db

# Revisar logs
docker-compose logs api-ventas
```

### Out of Memory
```bash
# Aumentar límites en docker-compose.yml
deploy:
  resources:
    limits:
      memory: 1G

# O en Docker Desktop
# Settings > Resources > Memory > Aumentar
```

### Rebuild lento
```bash
# Limpiar caché de Docker
docker system prune -a

# O mantener caché entre builds
docker buildx build --cache-from=type=local,src=/path/to/cache ...
```

### Permisos denegados
```bash
# Agregar usuario actual a grupo docker
sudo usermod -aG docker $USER
newgrp docker

# O usar sudo
sudo docker-compose up
```

---

## 📚 Referencias Útiles

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Specification](https://docs.docker.com/compose/compose-file/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [Trivy Scanner](https://github.com/aquasecurity/trivy)
- [Docker Hub Documentation](https://docs.docker.com/docker-hub/)

---

## 📝 Checklist de Despliegue a Producción

- [ ] Cambiar `.env` con valores seguros (contraseñas fuertes)
- [ ] Actualizar `SPRING_PROFILES_ACTIVE=production`
- [ ] Cambiar puertos a valores estándar (80, 443)
- [ ] Agregar HTTPS/TLS (certificados SSL)
- [ ] Configurar respaldos de BD (backup automático)
- [ ] Implementar monitoreo (Prometheus, Grafana)
- [ ] Configurar logs centralizados (ELK Stack)
- [ ] Validar workflow CI/CD con test final
- [ ] Documentar procesos de rollback
- [ ] Entrenar equipo en operación

---

**Creado**: 2024
**Versión**: 1.0.0
**Mantenedor**: CITT
