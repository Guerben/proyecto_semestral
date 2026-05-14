# 📦 Proyecto Semestral - Docker & CI/CD

Configuración completa de Docker, Docker Compose y GitHub Actions para el proyecto semestral con dos APIs Spring Boot, Frontend React y MySQL.

## � Documentación Disponible

| Documento | Contenido | Tiempo |
|-----------|-----------|--------|
| **Este archivo** | Guía rápida de inicio | 5 min |
| [DOCKERFILES-EXPLICACION.md](./DOCKERFILES-EXPLICACION.md) | ⭐ Explica CADA LÍNEA de Dockerfiles y docker-compose | 45 min |
| [ARQUITECTURA.md](./ARQUITECTURA.md) | Diagrama de componentes y flujos de datos | 10 min |
| [DOCKER-GUIA-COMPLETA.md](./DOCKER-GUIA-COMPLETA.md) | Referencia exhaustiva y troubleshooting | 30 min |
| [INDICE.md](./INDICE.md) | Índice completo de documentación | - |

**Recomendación**: Si quieres entender cómo funcionan los Dockerfiles, lee [DOCKERFILES-EXPLICACION.md](./DOCKERFILES-EXPLICACION.md).

## �🚀 Inicio Rápido

### Opción 1: Con Make (Recomendado)
```bash
# Ver todos los comandos disponibles
make help

# Inicio rápido: build + up
make quick-start

# Ver estado
make docker-ps

# Ver logs
make docker-logs
```

### Opción 2: Con Docker Compose
```bash
# Crear archivo .env
cp .env.example .env

# Construir imágenes
docker-compose build

# Levantar servicios
docker-compose up -d

# Ver logs
docker-compose logs -f
```

## 🌐 Acceso a Servicios

| Servicio | URL | Usuario | Contraseña |
|----------|-----|---------|-----------|
| Frontend | http://localhost:3000 | - | - |
| API Ventas | http://localhost:8080 | - | - |
| API Despachos | http://localhost:8081 | - | - |
| MySQL | localhost:3306 | appuser | appuser123 |

## 📁 Estructura

```
proyecto-semestral/
├── docker-compose.yml           # Orquestación de servicios
├── .env.example                 # Variables de entorno
├── Makefile                     # Comandos útiles
├── DOCKER-GUIA-COMPLETA.md      # Documentación detallada
├── .github/workflows/           # Pipelines CI/CD
│   ├── build-api-ventas.yml
│   ├── build-api-despachos.yml
│   └── build-frontend.yml
└── proyecto semestral/
    ├── back-Ventas_SpringBoot/          # API Ventas
    │   └── Springboot-API-REST/Dockerfile
    ├── back-Despachos_SpringBoot/       # API Despachos
    │   └── Springboot-API-REST-DESPACHO/Dockerfile
    └── front_despacho/                  # Frontend React
        ├── Dockerfile
        └── nginx.conf
```

## 🐳 Comandos Básicos

### Construcción
```bash
make docker-build              # Todas las imágenes
make docker-build-ventas       # Solo API Ventas
make docker-build-despachos    # Solo API Despachos
make docker-build-frontend     # Solo Frontend
```

### Ejecución
```bash
make docker-up                 # Iniciar servicios
make docker-down               # Detener servicios
make docker-restart            # Reiniciar servicios
```

### Monitoreo
```bash
make docker-ps                 # Ver estado
make docker-logs               # Ver logs en tiempo real
make docker-logs-ventas        # Logs API Ventas
make docker-logs-despachos     # Logs API Despachos
make docker-logs-frontend      # Logs Frontend
make docker-logs-db            # Logs Base de datos
```

### Mantenimiento
```bash
make docker-clean              # Limpiar imágenes
make docker-prune              # Limpiar todo
make setup-env                 # Crear .env
```

### Publicación
```bash
make docker-tag                # Taggear imágenes
make docker-push               # Publicar en Docker Hub
```

## 🔐 Configuración de Seguridad

### Variables de Entorno (.env)
```bash
# Base de datos
DB_ROOT_PASSWORD=admin123
DB_NAME=proyecto_db
DB_USER=appuser
DB_PASSWORD=appuser123

# Puertos
VENTAS_PORT=8080
DESPACHOS_PORT=8081
FRONTEND_PORT=3000

# Spring Boot
SPRING_PROFILES_ACTIVE=development
```

### GitHub Secrets (para CI/CD)

Configurar en: **Settings > Secrets and variables > Actions**

```
DOCKER_HUB_USERNAME    # Tu usuario Docker Hub
DOCKER_HUB_TOKEN       # Token de Docker Hub
```

## 🔄 GitHub Actions - CI/CD

Los workflows se ejecutan automáticamente cuando:
- Haces `push` a `main` o `develop`
- Cambios en los respectivos directorios

**Workflows disponibles:**
- `build-api-ventas.yml` - Build + Test + Publish API Ventas
- `build-api-despachos.yml` - Build + Test + Publish API Despachos
- `build-frontend.yml` - Build + Lint + Test + Publish Frontend

**Características:**
✅ Build multiplataforma (amd64, arm64)
✅ Escaneo de vulnerabilidades (Trivy)
✅ Publicación en Docker Hub
✅ Versionado semántico

## 📚 Documentación Completa

Para información detallada, ver: [`DOCKER-GUIA-COMPLETA.md`](./DOCKER-GUIA-COMPLETA.md)

Incluye:
- ✅ Construcción y configuración
- ✅ Uso avanzado de Docker Compose
- ✅ Publicación en registros
- ✅ Setup de CI/CD
- ✅ Buenas prácticas de seguridad
- ✅ Troubleshooting

## ⚙️ Stack Técnico

**Backend:**
- Java 17
- Spring Boot 3.4.4
- Maven 3.9.6
- MySQL 8.0

**Frontend:**
- React 18
- Vite
- Node.js 18
- Nginx Alpine

**DevOps:**
- Docker 20.10+
- Docker Compose 2.0+
- GitHub Actions
- Docker Hub

## 🔒 Características de Seguridad

✅ **Multi-stage builds** - Reduce tamaño de imágenes
✅ **Usuario no-root** - Ejecuta sin permisos elevados
✅ **Health checks** - Verifica servicios activos
✅ **Limits de recursos** - CPU y memoria
✅ **Scan de vulnerabilidades** - Trivy en CI/CD
✅ **Secretos seguros** - Usa .env, no hardcodear
✅ **HTTPS ready** - Configuración para SSL/TLS

## 🆘 Troubleshooting

### Puerto en uso
```bash
# Cambiar puerto en .env
VENTAS_PORT=9000 docker-compose up -d
```

### BD no inicializa
```bash
docker-compose down db
docker volume rm isY1101_ep2_proyecto\ semestral_mysql-data
docker-compose up db -d
```

### API no conecta a BD
```bash
docker-compose exec api-ventas ping db
docker-compose logs api-ventas
```

### Ver más...
Ver sección **Troubleshooting** en [`DOCKER-GUIA-COMPLETA.md`](./DOCKER-GUIA-COMPLETA.md)

## 📝 Checklist Pre-Producción

- [ ] Variables de entorno configuradas
- [ ] Cambiar `SPRING_PROFILES_ACTIVE=production`
- [ ] HTTPS/TLS habilitado
- [ ] Backup automático de BD configurado
- [ ] Monitoreo y logs centralizados
- [ ] Workflow CI/CD testeado
- [ ] Documentación de rollback

## 🤝 Contribuir

1. Fork el repositorio
2. Crea una rama: `git checkout -b feature/mi-feature`
3. Commit: `git commit -am 'Add feature'`
4. Push: `git push origin feature/mi-feature`
5. Pull Request

## 📞 Soporte

Para problemas o preguntas:
- 📧 Email: soporte@citt.cl
- 📖 Docs: [DOCKER-GUIA-COMPLETA.md](./DOCKER-GUIA-COMPLETA.md)
- 🐛 Issues: [GitHub Issues](../../issues)

## 📄 Licencia

Este proyecto está bajo licencia MIT.

---

**Versión:** 1.0.0
**Última actualización:** 2024
**Mantenedor:** CITT
