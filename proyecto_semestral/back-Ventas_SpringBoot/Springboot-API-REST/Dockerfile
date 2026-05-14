# ETAPA 1: BUILD - Compilar la aplicación Spring Boot con Maven
FROM maven:3.9.6-eclipse-temurin-17 AS builder
# Establecer directorio de trabajo
WORKDIR /app
COPY pom.xml .
# Descargar dependencias (caché layer)
RUN mvn dependency:go-offline -B
COPY src ./src
# Compilar la aplicación y generar JAR
RUN mvn clean package -DskipTests -B
# ETAPA 2: RUNTIME - Ejecutar la aplicación optimizada
FROM eclipse-temurin:17-jre-alpine
# Etiquetas de metadatos para identificar la imagen
LABEL maintainer="CITT"
LABEL description="API REST Spring Boot - Servicio de Ventas"
LABEL version="1.0.0"
# Establecer zona horaria y wget (healthcheck de Docker)
RUN apk add --no-cache tzdata wget
# Crear usuario no-root por seguridad
RUN addgroup -g 1001 appgroup && \
    adduser -D -u 1001 -G appgroup appuser
# Establecer directorio de trabajo
WORKDIR /app
# Copiar JAR compilado desde etapa anterior (multi-stage)
COPY --from=builder /app/target/*.jar app.jar
# Cambiar propietario del archivo
RUN chown -R appuser:appgroup /app
# Cambiar a usuario no-root
USER appuser
# Puerto en el que escucha la aplicación
EXPOSE 8080
# Health check para verificar que la aplicación está activa
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -q -O - http://localhost:8080/actuator/health || exit 1
# Comando de inicio con JVM optimizado para contenedores
ENTRYPOINT ["java", "-jar", \
    "-Xmx256m", \
    "-XX:+UseContainerSupport", \
    "-XX:InitialRAMPercentage=50.0", \
    "-XX:MaxRAMPercentage=80.0", \
    "app.jar"]