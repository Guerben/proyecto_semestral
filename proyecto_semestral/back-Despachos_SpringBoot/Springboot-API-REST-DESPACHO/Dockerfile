# ETAPA 1: BUILD - Compilar la aplicación Spring Boot con Maven
FROM maven:3.9.6-eclipse-temurin-17 AS builder
# Establecer directorio de trabajo
WORKDIR /app
# Copiar archivo de configuración de Maven
COPY pom.xml .
# Descargar dependencias (caché layer para acelerar builds)
RUN mvn dependency:go-offline -B
# Copiar código fuente de la aplicación
COPY src ./src
# Compilar la aplicación y generar archivo JAR empaquetado
RUN mvn clean package -DskipTests -B
# ETAPA 2: RUNTIME - Ejecutar la aplicación optimizada en contenedor
FROM eclipse-temurin:17-jre-alpine
# Etiquetas de metadatos para identificar, versionar y documentar la imagen
LABEL maintainer="CITT"
LABEL description="API REST Spring Boot - Servicio de Despachos"
LABEL version="1.0.0"
# Instalar utilidades necesarias y configurar zona horaria (wget = healthcheck Docker)
RUN apk add --no-cache tzdata wget
ENV TZ=America/Santiago
# Crear usuario no-root por razones de seguridad en contenedores
RUN addgroup -g 1001 appgroup && \
    adduser -D -u 1001 -G appgroup appuser
# Establecer directorio de trabajo en el contenedor
WORKDIR /app
# Copiar JAR compilado desde la etapa de build (multi-stage build pattern)
COPY --from=builder /app/target/*.jar app.jar
# Cambiar propietario del archivo JAR al usuario no-root
RUN chown -R appuser:appgroup /app
# Cambiar a usuario no-root para ejecutar la aplicación de forma segura
USER appuser
# Exponer el puerto en el que la aplicación escucha peticiones HTTP
EXPOSE 8081
# Verificación de salud del contenedor - valida que la aplicación esté respondiendo
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -q -O - http://localhost:8081/actuator/health || exit 1
# Comando de inicio con optimizaciones JVM para contenedores
# Incluye límites de memoria y settings para mejor performance
ENTRYPOINT ["java", "-jar", \
    "-Xmx256m", \
    "-XX:+UseContainerSupport", \
    "-XX:InitialRAMPercentage=50.0", \
    "-XX:MaxRAMPercentage=80.0", \
    "app.jar"]
