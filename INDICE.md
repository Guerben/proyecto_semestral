# 📚 Índice de Documentación - Proyecto Semestral Docker & CI/CD

**Último actualizado:** 2024
**Versión:** 1.0.0
**Mantenedor:** CITT

---

## 🎯 ¿Por Dónde Empezar?

### 👤 Para Desarrolladores (Inicio Rápido)
1. Lee: [README-DOCKER.md](./README-DOCKER.md) - **5 minutos**
2. Ejecuta: `make quick-start` - **2 minutos**
3. Accede: http://localhost:3000
4. ✅ ¡Listo!

### � Para Entender Docker en Detalle
1. Lee: [DOCKERFILES-EXPLICACION.md](./DOCKERFILES-EXPLICACION.md) - **⭐ COMPLETO**
   - Explica CADA LÍNEA de los Dockerfiles
   - Explica CADA LÍNEA del docker-compose.yml
   - Conceptos clave: multi-stage, healthcheck, networks
   - **Tiempo**: 45-60 minutos para entender completamente
2. Luego lee: [ARQUITECTURA.md](./ARQUITECTURA.md) - Ver flujos en contexto
3. Finalmente: [DOCKER-GUIA-COMPLETA.md](./DOCKER-GUIA-COMPLETA.md) - Referencia

### 👨‍💼 Para DevOps/Infraestructura
1. Lee: [ARQUITECTURA.md](./ARQUITECTURA.md) - **10 minutos**
2. Lee: [DOCKERFILES-EXPLICACION.md](./DOCKERFILES-EXPLICACION.md) - **45 minutos**
3. Lee: [DOCKER-GUIA-COMPLETA.md](./DOCKER-GUIA-COMPLETA.md) - **30 minutos**
4. Configura: [.github/SETUP-SECRETS.md](./.github/SETUP-SECRETS.md) - **5 minutos**
4. ✅ CI/CD configurado

### 👨‍💻 Para Desarrolladores Backend (Spring Boot)
1. Lee: [SPRING-BOOT-DOCKER-CONFIG.md](./SPRING-BOOT-DOCKER-CONFIG.md)
2. Configura: `application.properties`
3. Agrega dependencias: `pom.xml`
4. Test: `docker-compose up api-ventas`

---

## 📋 Documentación por Tema

### 🚀 INICIO RÁPIDO
| Archivo | Propósito | Tiempo |
|---------|----------|--------|
| [README-DOCKER.md](./README-DOCKER.md) | Guía de inicio rápido | 5 min |
| [Makefile](./Makefile) | Comandos útiles | - |
| [.env.example](./.env.example) | Variables de entorno | - |

### 🏗️ ARQUITECTURA
| Archivo | Propósito | Tiempo |
|---------|----------|--------|
| [ARQUITECTURA.md](./ARQUITECTURA.md) | Diagrama de componentes | 10 min |
| [docker-compose.yml](./docker-compose.yml) | Orquestación de servicios | - |
| [DOCKER-GUIA-COMPLETA.md](./DOCKER-GUIA-COMPLETA.md) | Documentación exhaustiva | 30 min |

### 🐳 DOCKERFILES
| Archivo | Servicio | Lenguaje |
|---------|----------|----------|
| [back-Ventas/.../Dockerfile](./proyecto%20semestral/back-Ventas_SpringBoot/Springboot-API-REST/Dockerfile) | API Ventas | Java/Spring Boot |
| [back-Despachos/.../Dockerfile](./proyecto%20semestral/back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO/Dockerfile) | API Despachos | Java/Spring Boot |
| [front_despacho/Dockerfile](./proyecto%20semestral/front_despacho/Dockerfile) | Frontend | React + Nginx |

### ⚙️ CONFIGURACIÓN
| Archivo | Propósito | Audience |
|---------|----------|----------|
| [SPRING-BOOT-DOCKER-CONFIG.md](./SPRING-BOOT-DOCKER-CONFIG.md) | Config Spring Boot | Backend |
| [proyecto semestral/front_despacho/nginx.conf](./proyecto%20semestral/front_despacho/nginx.conf) | Config Nginx | Frontend |
| [.env.example](./.env.example) | Variables de entorno | All |

### 🔄 CI/CD & GITHUB ACTIONS
| Archivo | Propósito | Triggers |
|---------|----------|----------|
| [.github/workflows/build-api-ventas.yml](./.github/workflows/build-api-ventas.yml) | Build API Ventas | Push main/develop |
| [.github/workflows/build-api-despachos.yml](./.github/workflows/build-api-despachos.yml) | Build API Despachos | Push main/develop |
| [.github/workflows/build-frontend.yml](./.github/workflows/build-frontend.yml) | Build Frontend | Push main/develop |
| [.github/SETUP-SECRETS.md](./.github/SETUP-SECRETS.md) | Setup Secrets | One-time |

### 📖 GUÍAS ESPECÍFICAS
| Archivo | Tema | Duración |
|---------|------|----------|
| [DOCKER-GUIA-COMPLETA.md](./DOCKER-GUIA-COMPLETA.md) | Todo sobre Docker | 30 min |
| [SPRING-BOOT-DOCKER-CONFIG.md](./SPRING-BOOT-DOCKER-CONFIG.md) | Spring Boot en Docker | 15 min |
| [.github/SETUP-SECRETS.md](./.github/SETUP-SECRETS.md) | GitHub Secrets | 10 min |
| [RESUMEN-CAMBIOS.md](./RESUMEN-CAMBIOS.md) | Cambios realizados | 5 min |

---

## 🔗 Navegación Rápida

### 📦 Quiero...

#### ...levantar los servicios localmente
1. `make quick-start` o `docker-compose up -d`
2. Acceder a http://localhost:3000
3. Ver [README-DOCKER.md](./README-DOCKER.md)

#### ...construir mis propias imágenes
1. Editar Dockerfiles
2. `docker-compose build`
3. `docker push` a Docker Hub
4. Ver [DOCKER-GUIA-COMPLETA.md](./DOCKER-GUIA-COMPLETA.md#publicación-en-registros)

#### ...configurar GitHub Actions
1. Agregar Secrets en GitHub
2. Ver [.github/SETUP-SECRETS.md](./.github/SETUP-SECRETS.md)
3. Hacer push a `main` para triggerear workflow

#### ...entender la arquitectura
1. Ver [ARQUITECTURA.md](./ARQUITECTURA.md)
2. Leer diagramas de componentes
3. Entender flujo de datos

#### ...configurar Spring Boot para Docker
1. Ver [SPRING-BOOT-DOCKER-CONFIG.md](./SPRING-BOOT-DOCKER-CONFIG.md)
2. Agregar dependencias en `pom.xml`
3. Configurar `application.properties`

#### ...publicar en Docker Hub
1. Ver [DOCKER-GUIA-COMPLETA.md](./DOCKER-GUIA-COMPLETA.md#publicación-en-registros)
2. Generar Docker Hub Token
3. Configurar secretos en GitHub
4. El workflow automatiza el resto

#### ...resolver un problema
1. Buscar en [DOCKER-GUIA-COMPLETA.md](./DOCKER-GUIA-COMPLETA.md#troubleshooting)
2. Ejecutar comandos de debug
3. Ver logs: `make docker-logs`

#### ...aprender sobre seguridad
1. Ver [DOCKER-GUIA-COMPLETA.md](./DOCKER-GUIA-COMPLETA.md#buenas-prácticas-de-seguridad)
2. Leer sobre multi-stage builds
3. Verificar uso de usuario no-root

---

## 📊 Estructura de Archivos

```
ISY1101_EP2_Proyecto Semestral/
│
├── 📖 DOCUMENTACIÓN
│   ├── README-DOCKER.md                    # ← EMPEZAR AQUÍ (guía rápida)
│   ├── DOCKERFILES-EXPLICACION.md          # ⭐ COMPLETO: Explica cada línea
│   ├── ARQUITECTURA.md                     # Diagrama + flujos de datos
│   ├── DOCKER-GUIA-COMPLETA.md             # Referencia exhaustiva
│   ├── SPRING-BOOT-DOCKER-CONFIG.md        # Config Spring Boot
│   ├── RESUMEN-CAMBIOS.md                  # Cambios realizados
│   └── 📇 INDICE.md                        # Este archivo
│
├── ⚙️ CONFIGURACIÓN
│   ├── docker-compose.yml                  # Orquestación principal
│   ├── .env.example                        # Variables de entorno
│   ├── .dockerignore                       # Exclusiones Docker
│   ├── .gitignore                          # Exclusiones Git
│   ├── Makefile                            # Comandos útiles
│   └── .github/
│       ├── SETUP-SECRETS.md                # Setup GitHub Secrets
│       └── workflows/
│           ├── build-api-ventas.yml        # CI/CD Ventas
│           ├── build-api-despachos.yml     # CI/CD Despachos
│           └── build-frontend.yml          # CI/CD Frontend
│
└── 🐳 PROYECTO
    └── proyecto semestral/
        ├── back-Ventas_SpringBoot/
        │   └── Springboot-API-REST/
        │       └── Dockerfile               # API Ventas
        ├── back-Despachos_SpringBoot/
        │   └── Springboot-API-REST-DESPACHO/
        │       └── Dockerfile               # API Despachos
        └── front_despacho/
            ├── Dockerfile                   # Frontend React
            └── nginx.conf                   # Config Nginx
```

---

## ✅ Checklist de Implementación

### Fase 1: Setup Local
- [ ] Clonar repositorio
- [ ] Instalar Docker 20.10+
- [ ] Instalar Docker Compose 2.0+
- [ ] Ejecutar `make quick-start`
- [ ] Acceder a http://localhost:3000
- [ ] Ver logs: `make docker-logs`

### Fase 2: Configuración del Proyecto
- [ ] Revisar `application.properties` en Spring Boot
- [ ] Agregar dependencias necesarias en `pom.xml`
- [ ] Probar conexión a BD localmente
- [ ] Verificar health checks: `/actuator/health`

### Fase 3: CI/CD Setup
- [ ] Crear token en Docker Hub
- [ ] Agregar `DOCKER_HUB_USERNAME` a GitHub Secrets
- [ ] Agregar `DOCKER_HUB_TOKEN` a GitHub Secrets
- [ ] Hacer push a rama `main` o `develop`
- [ ] Verificar que workflow se ejecuta
- [ ] Confirmar que imagen se publicó en Docker Hub

### Fase 4: Producción
- [ ] Cambiar `.env` con valores de producción
- [ ] Activar HTTPS/SSL
- [ ] Configurar backup automático de BD
- [ ] Configurar monitoreo y alertas
- [ ] Documentar procedimiento de rollback
- [ ] Entrenar equipo

---

## 🎓 Recursos de Aprendizaje

### Docker & Contenedores
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Specification](https://docs.docker.com/compose/compose-file/)
- [Best Practices for Writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

### GitHub Actions
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Security Hardening for GitHub Actions](https://docs.github.com/en/actions/security-guides)

### Spring Boot
- [Spring Boot Official Guide](https://spring.io/projects/spring-boot)
- [Spring Data JPA](https://spring.io/projects/spring-data-jpa)
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)

### Seguridad
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [OWASP Container Security](https://owasp.org/www-project-container-security/)
- [Trivy Scanner](https://github.com/aquasecurity/trivy)

---

## 🆘 Soporte & FAQ

### ¿Cómo levanto los servicios?
```bash
make quick-start
# O sin make:
docker-compose up -d
```

### ¿Cuáles son las URLs de acceso?
- Frontend: http://localhost:3000
- API Ventas: http://localhost:8080/swagger-ui.html
- API Despachos: http://localhost:8081/swagger-ui.html
- MySQL: localhost:3306

### ¿Cómo veo los logs?
```bash
make docker-logs
# O specific service:
make docker-logs-ventas
```

### ¿Cómo publico en Docker Hub?
Ver [.github/SETUP-SECRETS.md](./.github/SETUP-SECRETS.md) para setup
Luego: `make docker-push`

### ¿Qué hago si falla el workflow?
1. Ve a GitHub Actions
2. Selecciona el workflow que falló
3. Lee los logs de error
4. Busca la solución en [DOCKER-GUIA-COMPLETA.md](./DOCKER-GUIA-COMPLETA.md#troubleshooting)

### ¿Puedo cambiar los puertos?
Sí, edita `.env`:
```
VENTAS_PORT=9000
DESPACHOS_PORT=9001
FRONTEND_PORT=4000
```

---

## 📞 Contacto & Soporte

- 📧 **Email:** soporte@citt.cl
- 🐛 **Issues:** Crear en GitHub
- 📖 **Docs:** Este índice + documentación vinculada
- 💬 **Chat:** [Slack/Teams si aplica]

---

## 📄 Versionado

| Versión | Fecha | Cambios |
|---------|-------|---------|
| 1.0.0 | 2024 | Release inicial |
| - | - | Documentación completa |
| - | - | Workflows CI/CD |
| - | - | Dockerfiles optimizados |

---

## 🎉 ¡Listo para empezar!

```bash
# Opción 1: Con make (recomendado)
make help          # Ver todos los comandos
make quick-start   # Build + run

# Opción 2: Con docker-compose
docker-compose up -d

# Ver estado
docker-compose ps

# Acceder
open http://localhost:3000
```

---

**¡Buena suerte! 🚀**

Generado: 2024
Versión: 1.0.0
Proyecto: ISY1101 - Proyecto Semestral
