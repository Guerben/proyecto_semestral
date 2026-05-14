# ============================================================================
# Explicación Detallada: Dockerfiles y docker-compose.yml
# ============================================================================

## 📚 Tabla de Contenidos

1. [Conceptos Clave](#conceptos-clave)
2. [Dockerfile - API Spring Boot](#dockerfile---api-spring-boot)
3. [Dockerfile - Frontend React](#dockerfile---frontend-react)
4. [docker-compose.yml](#docker-composeyml)
5. [Flujos y Ejemplos](#flujos-y-ejemplos)

---

## 🎯 Conceptos Clave

### Multi-Stage Build
Es una técnica que permite tener **múltiples etapas** en un mismo Dockerfile:
- **Etapa 1 (BUILD)**: Compilar la aplicación con herramientas pesadas
- **Etapa 2 (RUNTIME)**: Ejecutar solo lo necesario sin herramientas de compilación

**Ventaja**: La imagen final es mucho más pequeña (75% de reducción)

### Usuario No-Root
Por seguridad, los contenedores NO deben ejecutarse como `root`:
- Limita daños si alguien accede al contenedor
- Restringe permisos de archivos y procesos
- Mejor auditoría y control

### Health Check
Un test automático que verifica si el servicio está funcionando:
- Se ejecuta cada cierto tiempo (interval)
- Si falla demasiadas veces, el contenedor se marca como "unhealthy"
- Docker Compose espera a que sea healthy antes de continuar

---

## 🐳 Dockerfile - API Spring Boot

**Ubicación**: `proyecto semestral/back-Ventas_SpringBoot/Springboot-API-REST/Dockerfile`

### Línea por Línea

```dockerfile
# ============================================================================
# ETAPA 1: BUILD - Compilar la aplicación Spring Boot con Maven
# ============================================================================
```
**¿Qué es?**: Comentario que marca la inicio de la etapa de compilación.
**Función**: Documentar el propósito de esta sección.

```dockerfile
FROM maven:3.9.6-eclipse-temurin-17 AS builder
```
**¿Qué es?**: Imagen base que contiene Maven + Java 17
**Función**: 
- `maven:3.9.6`: Incluye Maven (compilador) y Java 17
- `AS builder`: Nombra esta etapa como "builder" para referirla después
- **Tamaño**: ~1.5GB (sera descartado después)

**Analogía**: Es como tener un carpintero completo con todas sus herramientas.

```dockerfile
WORKDIR /app
```
**¿Qué es?**: Directorio de trabajo dentro del contenedor
**Función**: 
- Los comandos siguientes se ejecutarán en `/app`
- Si no existe, se crea automáticamente
- Similar a `cd /app` en terminal

```dockerfile
COPY pom.xml .
```
**¿Qué es?**: Copia el archivo pom.xml desde tu PC al contenedor
**Función**:
- `pom.xml`: Define dependencias del proyecto (Maven)
- `.`: Copia a `/app/` (WORKDIR actual)
- Se copia primero para aprovechar caché de Docker

**Analogía**: Llevar la lista de materiales necesarios antes que el código.

```dockerfile
RUN mvn dependency:go-offline -B
```
**¿Qué es?**: Descarga todas las dependencias Maven offline
**Función**:
- `-B`: Batch mode (sin preguntas interactivas)
- Descarga librerías a ~/.m2/repository
- Crea una capa de caché que Docker reutiliza
- **Beneficio**: Si el código cambia pero pom.xml no, esta etapa se salta

**Analogía**: Comprar todos los materiales antes de empezar a construir.

```dockerfile
COPY src ./src
```
**¿Qué es?**: Copia tu código fuente al contenedor
**Función**:
- `src`: Carpeta con todo el código Java
- `./src`: Copia a `/app/src` (dentro del contenedor)
- Se copia DESPUÉS de las dependencias para mejor caché

```dockerfile
RUN mvn clean package -DskipTests -B
```
**¿Qué es?**: Compila el código y genera JAR
**Función**:
- `clean`: Limpia compilaciones anteriores
- `package`: Crea archivo JAR en `target/`
- `-DskipTests`: Salta pruebas (más rápido)
- `-B`: Batch mode
- **Resultado**: Genera `target/app.jar` (~300MB)

**Analogía**: Construir el mueble completo en el taller.

---

```dockerfile
# ============================================================================
# ETAPA 2: RUNTIME - Ejecutar la aplicación optimizada
# ============================================================================
```
**¿Qué es?**: Marca el inicio de la etapa de ejecución
**Función**: Comentario descriptivo.

```dockerfile
FROM eclipse-temurin:17-jre-alpine
```
**¿Qué es?**: Imagen base para ejecutar Java (NO compilar)
**Función**:
- `eclipse-temurin:17`: Java Runtime Environment (JRE) versión 17
- `alpine`: Sistema operativo ultra ligero (~5MB)
- **Tamaño**: ~130MB (MUCHO más pequeño que maven:1.5GB)
- **Diferencia**: JRE solo ejecuta, no compila

**Analogía**: Ir a la casa del cliente sin todas las herramientas del taller.

```dockerfile
LABEL maintainer="CITT"
LABEL description="API REST Spring Boot - Servicio de Ventas"
LABEL version="1.0.0"
```
**¿Qué es?**: Metadatos de la imagen
**Función**:
- Documentación sobre quién mantiene esta imagen
- Qué hace
- Versión
- **Beneficio**: Facilita tracking e identificación

```dockerfile
RUN apk add --no-cache tzdata
ENV TZ=America/Santiago
```
**¿Qué es?**: Configura la zona horaria
**Función**:
- `apk`: Package manager de Alpine
- `--no-cache`: No guarda caché de instalación (ahorra espacio)
- `tzdata`: Paquete con zonas horarias
- `ENV TZ`: Variable de entorno con zona horaria

**¿Por qué?**: Los logs y timestamps usan la zona horaria del contenedor.

```dockerfile
RUN addgroup -g 1001 appgroup && \
    adduser -D -u 1001 -G appgroup appuser
```
**¿Qué es?**: Crea usuario no-root
**Función**:
- `addgroup`: Crea grupo "appgroup" con ID 1001
- `adduser`: Crea usuario "appuser"
- `-D`: No pide contraseña
- `-u 1001`: ID del usuario
- `-G appgroup`: Agrega a grupo appgroup
- **Seguridad**: La app corre sin permisos de root

**Analogía**: Crear un empleado limitado en lugar de dar acceso de administrador.

```dockerfile
WORKDIR /app
```
**¿Qué es?**: Directorio de trabajo en la etapa 2
**Función**: 
- En esta etapa (runtime), el directorio es `/app`
- Diferente de la etapa 1 (solo herencia de nombre)

```dockerfile
COPY --from=builder /app/target/*.jar app.jar
```
**¿Qué es?**: Copia el JAR compilado desde la etapa 1 a la etapa 2
**Función**:
- `--from=builder`: Toma archivo de la etapa "builder"
- `/app/target/*.jar`: JAR compilado en etapa 1
- `app.jar`: Lo copia a `/app/app.jar` en etapa 2
- **Resultado**: Solo el JAR (~300MB), sin Maven (~1.5GB)

**Analogía**: Llevar solo el mueble terminado a la casa, sin herramientas.

```dockerfile
RUN chown -R appuser:appgroup /app
```
**¿Qué es?**: Cambia propietario del directorio
**Función**:
- `-R`: Recursivo (aplica a todas las carpetas adentro)
- `appuser:appgroup`: Nuevo propietario
- **Seguridad**: El usuario appuser es dueño de sus archivos

```dockerfile
USER appuser
```
**¿Qué es?**: Cambia al usuario no-root
**Función**:
- Desde aquí en adelante, TODOS los comandos se ejecutan como appuser
- Si algún atacante accede al contenedor, no es root
- **Seguridad**: Limita daños potenciales

```dockerfile
EXPOSE 8080
```
**¿Qué es?**: Declara qué puerto usa la aplicación
**Función**:
- Documentación: "esta aplicación usa puerto 8080"
- **NO expone automáticamente** (eso lo hace docker-compose)
- Permite que Docker sepa qué puerto esperar

**Analogía**: Un letrero que dice "esta tienda usa la puerta principal".

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -q -O - http://localhost:8080/actuator/health || exit 1
```
**¿Qué es?**: Test automático de salud del servicio
**Función**:
- `--interval=30s`: Chequea cada 30 segundos
- `--timeout=5s`: Espera máximo 5 segundos por respuesta
- `--start-period=10s`: Espera 10s antes del primer chequeo (tiempo de startup)
- `--retries=3`: Si falla 3 veces seguidas, marca como "unhealthy"
- `wget ... /actuator/health`: Hace GET a endpoint de salud de Spring Boot
- `|| exit 1`: Si falla, código de salida 1 (error)

**¿Por qué?**: docker-compose espera a que todos los servicios estén healthy antes de iniciar el siguiente.

```dockerfile
ENTRYPOINT ["java", "-jar", \
    "-Xmx256m", \
    "-XX:+UseContainerSupport", \
    "-XX:InitialRAMPercentage=50.0", \
    "-XX:MaxRAMPercentage=80.0", \
    "app.jar"]
```
**¿Qué es?**: Comando que ejecuta cuando inicia el contenedor
**Función**:
- `java -jar`: Ejecuta el archivo JAR con Java
- `-Xmx256m`: Máximo 256MB de RAM para la JVM
- `-XX:+UseContainerSupport`: JVM se da cuenta que está en contenedor
- `-XX:InitialRAMPercentage=50.0`: Usar 50% de RAM inicial
- `-XX:MaxRAMPercentage=80.0`: Usar máximo 80% de RAM disponible
- `app.jar`: El archivo a ejecutar

**¿Por qué estos parámetros?**: Optimiza Java para funcionar eficientemente en contenedores.

---

## 🎨 Dockerfile - Frontend React

**Ubicación**: `proyecto semestral/front_despacho/Dockerfile`

### Diferencias Principales

```dockerfile
FROM node:18-alpine AS builder
```
**¿Qué es?**: Imagen base con Node.js + npm
**Función**:
- `node:18`: Node.js versión 18 con npm
- Necesario para compilar React con Vite
- **Tamaño**: ~400MB
- **Se descartará** después de compilar

```dockerfile
WORKDIR /app
COPY package*.json ./
RUN npm ci
```
**¿Qué es?**: Instala dependencias Node.js
**Función**:
- `package*.json`: Copia package.json y package-lock.json
- `npm ci`: Instala exactamente las versiones especificadas (más seguro que npm install)
- Crea capa de caché

**Analogía**: Comprar las librerías JavaScript necesarias.

```dockerfile
COPY . .
RUN npm run build
```
**¿Qué es?**: Compila la aplicación React
**Función**:
- `COPY . .`: Copia TODO el código (src, componentes, etc.)
- `npm run build`: Ejecuta script de build en package.json
- **Resultado**: Genera carpeta `dist/` con HTML + CSS + JS optimizado
- **Tamaño**: Archivos estáticos (~10-50MB)

**Analogía**: Construir la página web completa lista para servir.

```dockerfile
FROM nginx:alpine
```
**¿Qué es?**: Imagen base con servidor web Nginx
**Función**:
- `nginx`: Servidor web ultra rápido
- `alpine`: Sistema operativo ligero
- **Tamaño**: ~40MB
- **Función**: Sirve archivos estáticos muy rápido

**Diferencia con etapa anterior**: 
- Etapa 1: Node.js (para compilar) → SE DESCARTA
- Etapa 2: Nginx (para servir) → SE MANTIENE

**Analogía**: Cambiar al empleado de entrega más rápido.

```dockerfile
RUN apk add --no-cache curl
```
**¿Qué es?**: Instala curl para healthcheck
**Función**:
- `curl`: Herramienta para hacer peticiones HTTP
- Usada por HEALTHCHECK para verificar que Nginx está activo

```dockerfile
COPY --from=builder /app/dist /usr/share/nginx/html
```
**¿Qué es?**: Copia archivos compilados desde etapa 1
**Función**:
- `--from=builder`: Toma desde etapa anterior
- `/app/dist`: Archivos compilados de React (HTML, CSS, JS)
- `/usr/share/nginx/html`: Donde Nginx sirve archivos
- **Tamaño**: Solo archivos necesarios (~10-50MB)

**Lo que NO se copia**: Node.js, npm, node_modules, código fuente (todo se descarta).

```dockerfile
RUN echo 'server { \
    listen 80; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    \
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ { \
        expires 1y; \
        add_header Cache-Control "public, immutable"; \
    } \
    \
    location / { \
        try_files $uri /index.html; \
    } \
    \
    location /health { \
        access_log off; \
        return 200 "healthy\n"; \
        add_header Content-Type text/plain; \
    } \
}' > /etc/nginx/conf.d/default.conf
```
**¿Qué es?**: Configuración de Nginx
**Función**:

1. **`listen 80`**: Escucha en puerto 80 (HTTP)
2. **`server_name _`**: Acepta cualquier dominio
3. **`root /usr/share/nginx/html`**: Directorio base de archivos
4. **`index index.html`**: Archivo por defecto

5. **Bloque de archivos estáticos**:
   - `location ~* \.(js|css|...)`: Busca archivos con esas extensiones
   - `expires 1y`: Cache de 1 año en el navegador
   - `Cache-Control "public, immutable"`: Nunca refrescar

6. **Bloque SPA (Single Page Application)**:
   - `location /`: Para cualquier ruta
   - `try_files $uri /index.html`: Si no existe archivo, sirve index.html
   - **¿Por qué?**: React router maneja rutas en el navegador, no en servidor

7. **Bloque Health Check**:
   - `location /health`: Endpoint especial
   - `return 200`: Responde siempre "OK" (200)
   - Usado por Docker para verificar que Nginx está activo

**Analogía**: Reglas sobre cómo servir archivos: cuáles guardar en caché, cómo manejar rutas, etc.

```dockerfile
RUN chown -R nginx:nginx /usr/share/nginx/html
```
**¿Qué es?**: Cambia propietario de los archivos
**Función**:
- `nginx:nginx`: Usuario y grupo nginx
- Permite que Nginx acceda a los archivos
- **Seguridad**: Nginx es usuario no-root

```dockerfile
EXPOSE 80
```
**¿Qué es?**: Declara puerto 80
**Función**: Documentación - Nginx usa puerto 80.

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/health || exit 1
```
**¿Qué es?**: Test de salud
**Función**:
- `curl -f http://localhost/health`: Hace GET a /health
- Si obtiene 200 OK, está healthy
- Si falla 3 veces, marcado como unhealthy

---

## ⚙️ docker-compose.yml

**Ubicación**: `docker-compose.yml` (raíz del proyecto)

### Estructura General

```yaml
version: '3.9'
```
**¿Qué es?**: Versión de Docker Compose
**Función**: Define características disponibles (más reciente = más características).

---

### SECCIÓN: networks

```yaml
networks:
  app-network:
    driver: bridge
    driver_opts:
      com.docker.network.driver.mtu: 1450
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

**¿Qué es?**: Define red de comunicación entre contenedores
**Función**:
- `app-network`: Nombre de la red
- `driver: bridge`: Tipo de red (conecta contenedores en la misma máquina)
- `subnet: 172.20.0.0/16`: Rango de IPs para los contenedores

**¿Por qué?**: Sin red, los contenedores no pueden comunicarse.

**Analogía**: Una red interna donde los contenedores pueden hablar entre sí usando DNS interno.

---

### SECCIÓN: volumes

```yaml
volumes:
  mysql-data:
    driver: local
  mysql-logs:
    driver: local
```

**¿Qué es?**: Define almacenamiento persistente
**Función**:
- `mysql-data`: Volumen para datos (tablas, registros)
- `mysql-logs`: Volumen para logs de MySQL
- `driver: local`: Almacenamiento en la máquina local

**¿Por qué?**: Si el contenedor MySQL se elimina, los datos NO se pierden (guardados en volumen).

**Analogía**: Un armario externo donde guardar documentos importantes, no dentro de la casa (contenedor).

---

### SECCIÓN: services - DATABASE

```yaml
services:
  db:
    image: mysql:8.0-debian
    container_name: proyecto_mysql_db
```

**¿Qué es?**: Define servicio de base de datos
**Función**:
- `db`: Nombre del servicio (accesible como `db:3306` desde otros contenedores)
- `image: mysql:8.0-debian`: Descarga imagen de MySQL 8.0
- `container_name`: Nombre del contenedor para referencias

```yaml
    networks:
      app-network:
        ipv4_address: 172.20.0.2
```

**¿Qué es?**: Conecta el contenedor a la red
**Función**:
- `ipv4_address: 172.20.0.2`: IP fija para el contenedor
- Los otros contenedores accederán a `db:3306`

**¿Por qué?**: Otros servicios necesitan saber dónde encontrar MySQL.

```yaml
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD:-admin123}
      MYSQL_DATABASE: ${DB_NAME:-proyecto_db}
      MYSQL_USER: ${DB_USER:-appuser}
      MYSQL_PASSWORD: ${DB_PASSWORD:-appuser123}
      TZ: America/Santiago
```

**¿Qué es?**: Variables de entorno para MySQL
**Función**:
- `${VARIABLE:-valor_por_defecto}`: Usa variable del .env o valor por defecto
- `MYSQL_ROOT_PASSWORD`: Contraseña de root
- `MYSQL_DATABASE`: Base de datos a crear
- `MYSQL_USER`: Usuario para apps (no root)
- `MYSQL_PASSWORD`: Contraseña del usuario
- `TZ`: Zona horaria

**¿Por qué?**: MySQL lee estas variables en startup y crea usuario/BD automáticamente.

```yaml
    ports:
      - "${DB_PORT:-3306}:3306"
```

**¿Qué es?**: Mapeo de puertos
**Función**:
- `host:container` = Exterior:Interior
- `3306:3306`: Puerto 3306 en tu PC se mapea a puerto 3306 del contenedor
- **Desde host**: `localhost:3306`
- **Desde otros contenedores**: `db:3306`

```yaml
    volumes:
      - mysql-data:/var/lib/mysql
      - mysql-logs:/var/log/mysql
```

**¿Qué es?**: Monta volúmenes en el contenedor
**Función**:
- `mysql-data`: Volumen → `/var/lib/mysql` (donde MySQL guarda datos)
- `mysql-logs`: Volumen → `/var/log/mysql` (logs de MySQL)
- **Persistencia**: Si el contenedor se borra, datos persisten en volúmenes

**Analogía**: Carpetas compartidas entre host y contenedor.

```yaml
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
```

**¿Qué es?**: Test de salud de MySQL
**Función**:
- `mysqladmin ping`: Verifica que MySQL está respondiendo
- `interval: 10s`: Chequea cada 10s
- `retries: 5`: Después de 5 fallos, marca como unhealthy
- `start_period: 30s`: Espera 30s para startup
- **Beneficio**: Docker Compose espera a que MySQL esté healthy antes de iniciar APIs

---

### SECCIÓN: services - API VENTAS

```yaml
  api-ventas:
    build:
      context: proyecto semestral/back-Ventas_SpringBoot/Springboot-API-REST
      dockerfile: Dockerfile
    image: api-ventas:latest
    container_name: proyecto_api_ventas
```

**¿Qué es?**: Define servicio de API Ventas
**Función**:
- `build`: Construir imagen desde Dockerfile
- `context`: Directorio donde ejecutar `docker build`
- `dockerfile`: Nombre del archivo (Dockerfile)
- `image`: Nombre de la imagen resultante
- `container_name`: Nombre del contenedor

```yaml
    networks:
      app-network:
        ipv4_address: 172.20.0.3
```

**¿Qué es?**: Conecta a red
**Función**: IP 172.20.0.3 para acceso desde otros contenedores.

```yaml
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://db:3306/proyecto_db
      SPRING_DATASOURCE_USERNAME: ${DB_USER:-appuser}
      SPRING_DATASOURCE_PASSWORD: ${DB_PASSWORD:-appuser123}
      SPRING_JPA_HIBERNATE_DDL_AUTO: update
      SERVER_PORT: 8080
```

**¿Qué es?**: Variables de entorno para Spring Boot
**Función**:
- `SPRING_DATASOURCE_URL`: Conexión a BD
  - `db:3306`: Host (nombre del contenedor) y puerto
  - Resuelve automáticamente a IP 172.20.0.2 via DNS
- `USERNAME/PASSWORD`: Credenciales de la BD
- `DDL_AUTO: update`: Actualiza tablas si cambia código
- `SERVER_PORT: 8080`: Puerto de la API

**¿Por qué?**: Spring Boot lee estas variables en startup.

```yaml
    ports:
      - "8080:8080"
```

**¿Qué es?**: Mapea puerto 8080
**Función**:
- Exterior:Interior = `8080:8080`
- Accesible desde tu PC en `localhost:8080`

```yaml
    depends_on:
      db:
        condition: service_healthy
```

**¿Qué es?**: Define dependencias
**Función**:
- API Ventas NO inicia hasta que `db` esté healthy
- Evita que la API intente conectar antes de que MySQL esté listo

**Analogía**: "No empieces a cocinar hasta que los ingredientes lleguen".

```yaml
    restart: unless-stopped
```

**¿Qué es?**: Política de reinicio
**Función**:
- Si el contenedor falla, se reinicia automáticamente
- Excepto si se detiene manualmente (`docker-compose down`)

---

### SECCIÓN: services - API DESPACHOS

Similar a API Ventas pero:
- Puerto 8081 (para no conflictuar con Ventas)
- IP 172.20.0.4
- Su propio Dockerfile

---

### SECCIÓN: services - FRONTEND

```yaml
  frontend:
    build:
      context: proyecto semestral/front_despacho
      dockerfile: Dockerfile
    image: frontend:latest
    container_name: proyecto_frontend
```

**¿Qué es?**: Define servicio Frontend React
**Función**: Similar a APIs, pero con su Dockerfile.

```yaml
    ports:
      - "3000:80"
```

**¿Qué es?**: Mapea puerto 3000
**Función**:
- Exterior:Interior = `3000:80`
- Tu navegador: `localhost:3000`
- Dentro del contenedor: Nginx en puerto 80
- **Nota**: Nginx corre en puerto 80, pero es exposted como 3000 en el host

```yaml
    depends_on:
      api-ventas:
        condition: service_healthy
      api-despachos:
        condition: service_healthy
```

**¿Qué es?**: Frontend espera a APIs
**Función**:
- NO inicia hasta que ambas APIs estén healthy
- Asegura que cuando el frontend carga, las APIs están listas

---

## 🔄 Flujos y Ejemplos

### Flujo de Startup

```
docker-compose up
    ↓
1. Lee docker-compose.yml
    ↓
2. Crea red "app-network" (172.20.0.0/16)
    ↓
3. Crea volúmenes "mysql-data", "mysql-logs"
    ↓
4. Inicia contenedor "db" (MySQL)
    ├─ Espera HEALTHCHECK /mysqladmin ping
    ├─ Crea usuario "appuser" y BD "proyecto_db"
    └─ Marca como "healthy"
    ↓
5. Inicia contenedor "api-ventas"
    ├─ Construye imagen desde Dockerfile (si no existe)
    ├─ Ejecuta Spring Boot
    ├─ Se conecta a "db:3306" (resuelve a 172.20.0.2)
    ├─ Espera HEALTHCHECK /actuator/health
    └─ Marca como "healthy"
    ↓
6. Inicia contenedor "api-despachos" (similar a api-ventas)
    ↓
7. Inicia contenedor "frontend"
    ├─ Construye imagen desde Dockerfile
    ├─ Inicia Nginx
    ├─ Sirve archivos en puerto 80
    └─ Marca como "healthy"
    ↓
✅ SISTEMA LISTO
```

### Acceso Entre Servicios

#### Desde Frontend (Nginx) a API Ventas

**En el navegador**:
```
http://localhost:3000 → Tu PC
  ↓
Nginx en puerto 80 (dentro de contenedor frontend)
  ↓
JavaScript en el navegador hace petición:
fetch('http://localhost:8080/api/ventas')
  ↓
Tu PC localhost:8080 → mapeado a api-ventas:8080
```

**En el código JavaScript (mejor forma)**:
```javascript
// Frontend puede acceder a API directamente si en la misma red
fetch('http://api-ventas:8080/api/ventas')
// Resuelve a 172.20.0.3:8080
```

#### Desde API Ventas a MySQL

**En Spring Boot (application.properties)**:
```properties
spring.datasource.url=jdbc:mysql://db:3306/proyecto_db
```

**Resolución DNS**:
```
api-ventas (172.20.0.3) → solicita conexión a "db"
  ↓
Docker DNS interno resuelve "db" → 172.20.0.2
  ↓
Conexión a MySQL en 172.20.0.2:3306
```

---

## 📊 Comparación: Sin vs Con Docker

### SIN DOCKER (Máquina local)

```
Instalar:
├─ Java 17 ← 400MB
├─ Maven 3.9 ← 300MB
├─ Node 18 ← 800MB
├─ MySQL ← 400MB
├─ Nginx ← 200MB
└─ Todas las dependencias
TOTAL: ~5-10GB en tu PC

Problemas:
- ¿Versión de Java en prod vs dev?
- ¿Puertos en conflicto?
- ¿Variables de entorno diferentes?
- No reproducible en otra máquina
```

### CON DOCKER

```
Imágenes:
├─ api-ventas ← 300MB
├─ api-despachos ← 300MB
├─ frontend ← 150MB
├─ mysql ← 400MB
└─ (Nginx incluido en frontend)
TOTAL: ~1.1GB

Beneficios:
✅ Mismo ambiente dev/prod
✅ Reproducible en cualquier máquina
✅ Fácil compartir con equipo
✅ CI/CD automático
✅ Escalable a Kubernetes
```

---

## 🎯 Resumen

| Concepto | ¿Qué es? | Función |
|----------|----------|---------|
| **Dockerfile** | Instrucciones para construir imagen | Define cómo empaquetar la app |
| **Multi-stage** | 2+ etapas en 1 Dockerfile | Compilar en 1, ejecutar en otra (más pequeño) |
| **Imagen** | Plantilla de contenedor | Template lista para usar |
| **Contenedor** | Instancia ejecutable de imagen | APP funcionando |
| **docker-compose** | Orquesta múltiples contenedores | Define servicios, redes, volúmenes |
| **Red** | Conexión entre contenedores | Contenedores se hablan entre sí |
| **Volumen** | Almacenamiento persistente | Datos persisten si contenedor muere |
| **HEALTHCHECK** | Test automático | Docker verifica si servicio está OK |
| **depends_on** | Orden de inicio | A espera que B esté listo |

