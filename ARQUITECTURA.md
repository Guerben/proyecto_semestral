# ============================================================================
# Arquitectura del Proyecto - Docker & Componentes
# ============================================================================

## 📖 Guía de Lectura

Este documento explica **cómo funciona Docker en tu proyecto**, organizando:
1. **Conceptos básicos**: Qué son Dockerfiles y docker-compose
2. **Arquitectura visual**: Diagrama de componentes
3. **Explicación detallada**: Cada sección de los Dockerfiles
4. **Configuración**: Explicación del docker-compose.yml
5. **Flujo de datos**: Cómo se comunican los servicios

---

## 🎯 Conceptos Clave

### ¿Qué es un Dockerfile?
Un **Dockerfile** es un archivo de instrucciones que contiene los pasos para construir una **imagen Docker**. Una imagen es una plantilla que contiene todo lo necesario para ejecutar una aplicación (código, dependencias, configuración).

**Estructura típica:**
- **FROM**: Imagen base (sistema operativo + runtime)
- **RUN**: Comandos para instalar y configurar
- **COPY**: Copiar archivos desde tu máquina a la imagen
- **EXPOSE**: Puertos que expone la aplicación
- **CMD/ENTRYPOINT**: Comando que ejecuta cuando inicia el contenedor

**📖 Para entender CADA LÍNEA**: Lee [DOCKERFILES-EXPLICACION.md](./DOCKERFILES-EXPLICACION.md)

### ¿Qué es docker-compose.yml?
Es un archivo que **orquesta múltiples contenedores**. Define:
- Qué servicios correr
- Cómo conectarlos (redes)
- Volúmenes (almacenamiento persistente)
- Variables de entorno
- Dependencias entre servicios

**📖 Para entender CADA LÍNEA**: Lee [DOCKERFILES-EXPLICACION.md](./DOCKERFILES-EXPLICACION.md#-docker-composeyml)

---

## 🏗️ Arquitectura General

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         CLIENTE (Navegador)                             │
│                              :3000                                       │
└────────────────────────────┬──────────────────────────────────────────────┘
                             │ HTTP/REST
                             │
┌────────────────────────────▼──────────────────────────────────────────────┐
│                       FRONTEND (React)                                    │
│                    Puerto: 80 (en contenedor)                            │
│                    :3000 (host)                                          │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ Node:18-Alpine (Build) → Nginx:Alpine (Runtime)               │   │
│  │ Multi-stage Build para tamaño optimizado (~150MB)             │   │
│  │ Health Check: /health                                         │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└────────────────────┬───────────────────────────────┬──────────────────────┘
                     │                               │
                     │ API HTTP/JSON                 │ API HTTP/JSON
                     │ :8080                         │ :8081
                     │                               │
        ┌────────────▼──────────────┐    ┌──────────▼──────────────┐
        │   API VENTAS (Spring)      │    │ API DESPACHOS (Spring)  │
        │   Puerto: 8080             │    │ Puerto: 8081            │
        │                            │    │                         │
        │ ┌──────────────────────┐   │    │ ┌──────────────────────┐│
        │ │ Maven:3.9 (Build)    │   │    │ │ Maven:3.9 (Build)    ││
        │ │ ↓                    │   │    │ │ ↓                    ││
        │ │ OpenJDK:17 (Runtime) │   │    │ │ OpenJDK:17 (Runtime) ││
        │ │ ↓                    │   │    │ │ ↓                    ││
        │ │ app.jar (~300MB)     │   │    │ │ app.jar (~300MB)     ││
        │ │ Spring Boot 3.4.4    │   │    │ │ Spring Boot 3.4.4    ││
        │ │ Health: /actuator    │   │    │ │ Health: /actuator    ││
        │ │ Non-root user        │   │    │ │ Non-root user        ││
        │ └──────────────────────┘   │    │ └──────────────────────┘│
        └────────────┬────────────────┘    └────────────┬────────────┘
                     │                                  │
                     │ JDBC Connection (TCP 3306)      │
                     │                                  │
                     └──────────────────┬───────────────┘
                                        │
                        ┌───────────────▼────────────────┐
                        │    BASE DE DATOS (MySQL)       │
                        │    Puerto: 3306                │
                        │    Usuario: appuser            │
                        │    Contraseña: appuser123      │
                        │    Base: proyecto_db           │
                        │                                │
                        │ ┌────────────────────────────┐ │
                        │ │ MySQL:8.0-debian           │ │
                        │ │ Volúmenes:                 │ │
                        │ │  - mysql-data (persistencia)│ │
                        │ │  - mysql-logs              │ │
                        │ │ Health Check: mysqladmin   │ │
                        │ │ Non-root user              │ │
                        │ └────────────────────────────┘ │
                        └────────────────────────────────┘

```

---

## 🌐 Red Docker

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Network: app-network             │
│                    Type: bridge                             │
│                    Subnet: 172.20.0.0/16                    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ CONTENEDORES EN LA RED                               │   │
│  │                                                      │   │
│  │  frontend       172.20.0.5:80                        │   │
│  │  ├─ Accesible desde: http://frontend:80/            │   │
│  │  ├─ DNS interno: frontend                            │   │
│  │  └─ Health: /health                                  │   │
│  │                                                      │   │
│  │  api-ventas     172.20.0.3:8080                      │   │
│  │  ├─ Accesible desde: http://api-ventas:8080/        │   │
│  │  ├─ DNS interno: api-ventas                          │   │
│  │  └─ Health: /actuator/health                         │   │
│  │                                                      │   │
│  │  api-despachos  172.20.0.4:8081                      │   │
│  │  ├─ Accesible desde: http://api-despachos:8081/     │   │
│  │  ├─ DNS interno: api-despachos                       │   │
│  │  └─ Health: /actuator/health                         │   │
│  │                                                      │   │
│  │  db              172.20.0.2:3306                     │   │
│  │  ├─ Accesible desde: db:3306                         │   │
│  │  ├─ DNS interno: db (MySQL)                          │   │
│  │  └─ Health: mysqladmin ping -h db                    │   │
│  │                                                      │   │
│  │  COMUNICACIÓN INTERNA (dentro de la red):            │   │
│  │  • APIs pueden llamar a db usando nombre "db"        │   │
│  │  • Frontend puede acceder a APIs usando nombres      │   │
│  │  • DNS resolución automática                         │   │
│  │                                                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  PUERTOS EXPUESTOS AL HOST:                                │
│  • localhost:3000 → frontend:80                            │
│  • localhost:8080 → api-ventas:8080                        │
│  • localhost:8081 → api-despachos:8081                     │
│  • localhost:3306 → db:3306                                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Layers de Imágenes Docker

### API Spring Boot (Ventas/Despachos)

```
Stage 1: BUILD
┌─────────────────────────────────────┐
│ FROM maven:3.9.6-eclipse-temurin-17 │
│ WORKDIR /app                        │
│ COPY pom.xml .                      │
│ RUN mvn dependency:go-offline       │ ← Caché layer
│ COPY src ./src                      │
│ RUN mvn clean package               │ ← Genera JAR
│ SIZE: ~1.5GB (temporal, descartado) │
└─────────────────────────────────────┘
            │
            │ COPY --from=builder
            ▼
Stage 2: RUNTIME
┌──────────────────────────────────────┐
│ FROM eclipse-temurin:17-jre-alpine   │
│ RUN apk add tzdata                   │ ← TimeZone
│ RUN adduser appuser                  │ ← Non-root
│ COPY --from=builder app.jar          │ ← Solo JAR
│ USER appuser                         │
│ HEALTHCHECK /actuator/health         │
│ ENTRYPOINT java -jar app.jar         │
│ SIZE: ~300MB (imagen final)          │
└──────────────────────────────────────┘
```

### Frontend React

```
Stage 1: BUILD
┌────────────────────────────────────┐
│ FROM node:18-alpine                │
│ COPY package*.json ./              │
│ RUN npm ci                         │ ← Caché layer
│ COPY src ./src                     │
│ RUN npm run build                  │ ← Compila con Vite
│ SIZE: ~500MB (temporal, descartado)│
└────────────────────────────────────┘
            │
            │ COPY --from=builder /dist
            ▼
Stage 2: RUNTIME
┌────────────────────────────────────┐
│ FROM nginx:alpine                  │
│ COPY dist /usr/share/nginx/html    │ ← Solo archivos estáticos
│ COPY nginx.conf                    │ ← Configuración
│ USER nginx                         │ ← Non-root
│ HEALTHCHECK /health                │
│ CMD nginx -g daemon off            │
│ SIZE: ~150MB (imagen final)        │
└────────────────────────────────────┘
```

---

## 🔄 Flujo CI/CD

```
┌─────────────────────────────────────────────────────────────┐
│                      GitHub Repository                      │
│         push to main/develop → Cambios en servicios         │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
         ┌───────────────────────────────────┐
         │  GitHub Actions Workflow Trigger  │
         └────────────┬──────────────────────┘
                      │
         ┌────────────┴──────────────┐
         │                           │
         ▼                           ▼
    [LINT/TEST]              [BUILD STAGE]
    - ESLint                  - Checkout
    - Prettier                - Setup Buildx
    - Jest Tests              - Build image
         │                    - Multi-platform
         │                    - Tag with version
         │                    - Push to registry
         │                         │
         └────────────┬────────────┘
                      │
                      ▼
          [SECURITY SCAN - TRIVY]
          - Escanear vulnerabilidades
          - Generar SARIF report
          - Upload a GitHub Security tab
                      │
                      ▼
         ┌────────────────────────────┐
         │       Docker Hub           │
         │                            │
         │ ✓ api-ventas:1.0.0         │
         │ ✓ api-despachos:1.0.0      │
         │ ✓ frontend:1.0.0           │
         │ ✓ *:latest (branches)      │
         └────────────────────────────┘
```

---

## 🔐 Seguridad - Capas de Protección

```
┌──────────────────────────────────────────────────────────────┐
│ CAPA 1: Secretos (GitHub Secrets - Encriptados)             │
│ ├─ DOCKER_HUB_USERNAME                                      │
│ └─ DOCKER_HUB_TOKEN (Personal Access Token)                 │
└──────────────────────────────────────────────────────────────┘
                              ▼
┌──────────────────────────────────────────────────────────────┐
│ CAPA 2: Construcción Segura                                 │
│ ├─ Multi-stage builds (reduce attack surface)               │
│ ├─ Imágenes base minimales (Alpine)                         │
│ ├─ No incluye dev tools ni git history                      │
│ └─ Caché de dependencias independiente                      │
└──────────────────────────────────────────────────────────────┘
                              ▼
┌──────────────────────────────────────────────────────────────┐
│ CAPA 3: Runtime Seguro                                      │
│ ├─ Usuario no-root (appuser, uid 1001)                      │
│ ├─ Sistema de archivos read-only donde posible              │
│ ├─ Permisos restrictivos en archivos                        │
│ └─ Sin contraseñas en variables de entorno                  │
└──────────────────────────────────────────────────────────────┘
                              ▼
┌──────────────────────────────────────────────────────────────┐
│ CAPA 4: Escaneo de Vulnerabilidades (Trivy)                 │
│ ├─ Análisis de imagen antes de publicar                     │
│ ├─ Búsqueda de CVEs conocidos                               │
│ ├─ Reporte SARIF en GitHub Security tab                     │
│ └─ No fallar build (warnings solamente)                     │
└──────────────────────────────────────────────────────────────┘
                              ▼
┌──────────────────────────────────────────────────────────────┐
│ CAPA 5: Registros (Docker Hub)                              │
│ ├─ Imágenes versionadas (semver: 1.0.0)                     │
│ ├─ Etiquetas con commit SHA                                 │
│ ├─ Control de acceso (privado/público)                      │
│ └─ Auditoría de pushes                                      │
└──────────────────────────────────────────────────────────────┘
```

---

## 📊 Estadísticas de Imágenes

```
IMAGEN              TAMAÑO      LAYERS      BASE
────────────────────────────────────────────────────────────
api-ventas          ~300 MB     15-20       eclipse-temurin:17-jre-alpine
api-despachos       ~300 MB     15-20       eclipse-temurin:17-jre-alpine
frontend            ~150 MB     12-15       nginx:alpine
mysql               ~400 MB     10-12       mysql:8.0-debian
────────────────────────────────────────────────────────────
TOTAL (sin layers   ~1.1 GB
compartidos)

COMPARACIÓN SIN MULTI-STAGE:
Sin multi-stage     ~4.5 GB+    (30-40 layers)
Con multi-stage     ~1.1 GB     (12-20 layers)
REDUCCIÓN:          75%
```

---

## 🔄 Flujo de Datos

```
1. USUARIO NAVEGA A http://localhost:3000
   │
   ├─ Browser descarga index.html (React App)
   ├─ Descarga JavaScript + CSS bundles
   └─ Carga la aplicación
   
2. FRONTEND (React) HACE PETICIONES
   │
   ├─ GET /api/ventas → http://localhost:8080/api/ventas
   │   └─ (En Docker: http://api-ventas:8080/api/ventas)
   │
   └─ GET /api/despachos → http://localhost:8081/api/despachos
       └─ (En Docker: http://api-despachos:8081/api/despachos)

3. APIS (Spring Boot) PROCESAN PETICIONES
   │
   ├─ Validan datos
   ├─ Hacen queries a BD
   ├─ Retornan JSON
   └─ (Base de datos: db:3306)

4. BASE DE DATOS (MySQL)
   │
   ├─ Almacena datos
   ├─ Ejecuta queries
   └─ Retorna resultados

5. RESPUESTA A CLIENTE
   └─ APIs → Frontend → Browser (JSON)
```

---

## 📈 Escalabilidad Futura

```
Arquitectura Actual (Docker Compose)
└─ Desarrollo/Testing: ✓
└─ Producción: ✓ (con limites)

Evolución Recomendada
│
├─ Kubernetes (K8s)
│  ├─ Replicar servicios (HPA)
│  ├─ Balanceador de carga (Load Balancer)
│  ├─ Auto-scaling
│  └─ Servicios gestionados
│
├─ Docker Swarm
│  ├─ Orquestación de contenedores
│  ├─ Load balancing
│  ├─ Auto-scaling
│  └─ Administración simplificada
│
└─ Nginx/Reverse Proxy
   ├─ Balanceo de carga
   ├─ HTTPS termination
   └─ Caché de contenido
```

---

## 📝 Variables de Entorno

```
CATEGORÍA              VARIABLE                    VALOR
──────────────────────────────────────────────────────────────
BASE DE DATOS
                       DB_ROOT_PASSWORD            admin123
                       DB_NAME                     proyecto_db
                       DB_USER                     appuser
                       DB_PASSWORD                 appuser123
                       DB_PORT                     3306

APLICACIONES
                       VENTAS_PORT                 8080
                       DESPACHOS_PORT              8081
                       FRONTEND_PORT               3000
                       SPRING_PROFILES_ACTIVE      development

BUILD
                       BUILD_DATE                  2024-01-01T...
                       VCS_REF                     <commit-sha>
                       VERSION                     1.0.0
```

---

**Generado:** 2024
**Versión:** 1.0.0
