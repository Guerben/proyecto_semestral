# Despliegue en AWS EC2 con Docker y Amazon S3 (sin Docker Hub)

Guía **muy detallada** para desplegar **MySQL**, **API Ventas**, **API Despachos** y **Frontend** en **una instancia EC2**, usando **Amazon S3** como origen del código (carpeta o ZIP). Las imágenes Docker se **construyen en la propia EC2** con `docker compose build` (no hace falta subir imágenes a Docker Hub ni a otro registro).

> **Idea general:** subes el proyecto (o un ZIP generado por CI) a un **bucket S3**; la EC2 **descarga** ese contenido y ejecuta **Docker Compose** para construir y levantar contenedores. El archivo **`.env` con secretos** vive **solo en la EC2** (no debe subirse a S3).

---

## Tabla de contenidos

1. [Conceptos y arquitectura](#1-conceptos-y-arquitectura)
2. [Qué necesitas antes de empezar](#2-qué-necesitas-antes-de-empezar)
3. [Crear el bucket de Amazon S3](#3-crear-el-bucket-de-amazon-s3)
4. [IAM: permisos para subir archivos al bucket (tu PC o GitHub Actions)](#4-iam-permisos-para-subir-archivos-al-bucket-tu-pc-o-github-actions)
5. [IAM: rol para la EC2 (descargar desde S3)](#5-iam-rol-para-la-ec2-descargar-desde-s3)
6. [Crear la instancia EC2 y Security Group](#6-crear-la-instancia-ec2-y-security-group)
7. [Preparar la EC2: Docker, AWS CLI y carpetas](#7-preparar-la-ec2-docker-aws-cli-y-carpetas)
8. [Archivo `.env` en el servidor (obligatorio)](#8-archivo-env-en-el-servidor-obligatorio)
9. [Subir el proyecto al bucket (tres formas)](#9-subir-el-proyecto-al-bucket-tres-formas)
10. [Primera puesta en marcha en la EC2](#10-primera-puesta-en-marcha-en-la-ec2)
11. [Despliegue con GitHub Actions (ZIP → S3 → EC2)](#11-despliegue-con-github-actions-zip--s3--ec2)
12. [Actualizar la aplicación (ciclos posteriores)](#12-actualizar-la-aplicación-ciclos-posteriores)
13. [Verificación y diagnóstico](#13-verificación-y-diagnóstico)
14. [Problemas frecuentes y soluciones](#14-problemas-frecuentes-y-soluciones)
15. [Anexo: despliegue con registro Docker (opcional)](#15-anexo-despliegue-con-registro-docker-opcional)

---

## 1. Conceptos y arquitectura

### 1.1. Qué hace cada pieza

| Componente | Función |
|------------|---------|
| **Amazon S3** | Almacena una copia del repositorio (carpeta sincronizada o archivo `.zip`). Es el “almacén” desde el que la EC2 obtiene el `docker-compose.yml` y el código fuente para los `Dockerfile`. |
| **EC2** | Máquina virtual Linux donde está instalado **Docker**. Aquí se ejecutan `docker compose build` y `docker compose up`. |
| **Docker Compose** | Lee `docker-compose.yml` en la raíz del proyecto, construye las imágenes de los servicios `api-ventas`, `api-despachos`, `frontend` y levanta **MySQL** + las tres aplicaciones en una red interna. |
| **Security Group** | Firewall de AWS: decide qué puertos de la EC2 son accesibles desde Internet (por ejemplo HTTP 80 para el navegador, SSH 22 para administración). |
| **Archivo `.env` en la EC2** | Contiene contraseñas de MySQL y variables como `FRONTEND_PORT`. **No** debe versionarse en Git ni subirse a S3 en claro en entornos reales; en esta guía lo guardas solo en `/opt/isy1101/.env`. |

### 1.2. Flujo de datos (resumen visual)

```
Tu PC o GitHub Actions
        │
        │  aws s3 sync  o  aws s3 cp (ZIP)
        ▼
   Bucket S3  (releases/… o carpeta “proyecto”)
        │
        │  aws s3 cp / sync  (EC2 con rol IAM)
        ▼
   /opt/isy1101/repo/   ←  código del compose y “proyecto semestral/…”
   /opt/isy1101/.env    ←  solo en servidor (no viene del bucket)
        │
        │  docker compose --env-file /opt/isy1101/.env build && up
        ▼
   Contenedores: db, api-ventas, api-despachos, frontend (Nginx)
```

### 1.3. Por qué el `.env` está fuera de la carpeta sincronizada

Si usas `aws s3 sync s3://mi-bucket/carpeta/ /opt/isy1101/repo/ --delete`, cualquier archivo en `repo/` que **no** exista en el bucket puede **eliminarse**. Por eso la guía usa:

- **`/opt/isy1101/.env`** — secretos solo en la EC2.
- **`/opt/isy1101/repo/`** — contenido descargado desde S3 (código).
- Comando Compose: `docker compose --env-file /opt/isy1101/.env -f /opt/isy1101/repo/docker-compose.yml …` ejecutado con `cwd` en `repo/` o con rutas coherentes (ver sección 10).

Así una sincronización con `--delete` no borra tus contraseñas.

### 1.4. Puertos y seguridad

- **MySQL (3306)** solo dentro de la red Docker; **no** abras 3306 en el Security Group hacia `0.0.0.0/0`.
- Los usuarios acceden al **frontend** (Nginx) en el puerto que mapees (por ejemplo **80**). Las rutas `/api/v1/ventas` y `/api/v1/despachos` las proxifica el propio Nginx del contenedor `frontend` hacia las APIs internas.

---

## 2. Qué necesitas antes de empezar

1. Cuenta de **AWS** con permisos para crear S3, EC2 e IAM.
2. **Par de claves SSH** (.pem) para conectarte a la EC2.
3. En tu máquina local (opcional pero recomendable): [**AWS CLI v2**](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) instalado y configurado (`aws configure`) con un usuario IAM que pueda **subir** al bucket (si vas a subir desde tu PC).
4. Repositorio del proyecto clonado en tu PC (o acceso al ZIP que generará GitHub Actions).

---

## 3. Crear el bucket de Amazon S3

### Paso 3.1 — Abrir S3

1. Inicia sesión en la [consola de AWS](https://console.aws.amazon.com/).
2. En el buscador superior escribe **S3** y entra al servicio **S3**.

### Paso 3.2 — Crear bucket

1. Pulsa **Create bucket** (Crear bucket).
2. **Bucket name:** un nombre **único a nivel mundial** (ej. `isy1101-proyecto-guerb-2026`). Solo minúsculas, números y guiones; sin espacios.
3. **AWS Region:** elige la misma región donde crearás la EC2 (ej. `us-east-1` o `sa-east-1` São Paulo) para reducir latencia y simplificar permisos.
4. **Object Ownership:** deja **ACLs disabled (recommended)** salvo que tu organización exija lo contrario.
5. **Block Public Access settings for this bucket:** deja **activado** el bloqueo de acceso público (recomendado). El bucket **no** debe ser público; la EC2 accederá con **IAM (rol o credenciales)**.
6. **Bucket Versioning:** opcional; **Enable** si quieres poder recuperar versiones anteriores de los objetos.
7. **Default encryption:** habilita **SSE-S3** (o KMS si tu política lo exige).
8. Pulsa **Create bucket**.

### Paso 3.3 — Carpetas lógicas en el bucket (recomendación)

No es obligatorio crear “carpetas” en la consola (S3 es un espacio de claves), pero conviene una convención:

- `releases/latest.zip` — último paquete desplegado (útil con GitHub Actions).
- `releases/<commit-sha>.zip` — un ZIP por versión (auditoría).
- O bien `proyecto/` con `sync` de archivos sueltos si no usas ZIP.

La guía de **GitHub Actions** en este repo usa `releases/latest.zip` y `releases/<sha>.zip`.

---

## 4. IAM: permisos para subir archivos al bucket (tu PC o GitHub Actions)

Quien **suba** objetos al bucket (tu usuario en la PC o el rol/usuario que use GitHub Actions) necesita permisos de escritura **solo en ese bucket**.

### 4.1. Política JSON de ejemplo (sustituye el ARN del bucket)

En **IAM** → **Policies** → **Create policy** → pestaña **JSON** y pega (ajusta `BUCKET_NAME` y región si hace falta en el ARN):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListBucketForDeploy",
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::BUCKET_NAME"
    },
    {
      "Sid": "ReadWriteObjectsUnderReleases",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::BUCKET_NAME/releases/*"
    }
  ]
}
```

- Si también subes con prefijo `proyecto/`, añade otro `Resource`: `arn:aws:s3:::BUCKET_NAME/proyecto/*` y los mismos `Action` que necesites.

### 4.2. Usuario IAM para tu PC (acceso programático)

1. **IAM** → **Users** → **Create user**.
2. Nombre: ej. `s3-deploy-uploader`.
3. En **Set permissions**, adjunta la política que creaste (o crea **inline policy** con el JSON).
4. Tras crear el usuario: pestaña **Security credentials** → **Create access key** → uso típico **Command Line Interface (CLI)**.
5. Guarda **Access key ID** y **Secret access key** (solo se muestran una vez).
6. En tu PC:

```bash
aws configure
```

Introduce el Access key, el Secret, la región por defecto y el formato de salida (`json`).

### 4.3. (Opcional avanzado) GitHub Actions sin claves de larga duración — OIDC

Para no guardar `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` en GitHub:

1. En **IAM** → **Identity providers** → **Add provider** → **OpenID Connect** → URL `https://token.actions.githubusercontent.com`, Audience `sts.amazonaws.com`.
2. Crea un **rol IAM** con **Web identity** → elige el proveedor GitHub → **Audience** `sts.amazonaws.com`.
3. En **Trust policy** del rol, limita el repositorio, por ejemplo:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::TU_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:TU_ORG/TU_REPO:*"
        }
      }
    }
  ]
}
```

4. Adjunta al rol la política de S3 del apartado 4.1.
5. En el workflow usarías `aws-actions/configure-aws-credentials` con `role-to-assume` en lugar de access key. La guía del workflow en la sección 11 indica los secretos clásicos; puedes sustituirlos por OIDC cuando domines el flujo.

---

## 5. IAM: rol para la EC2 (descargar desde S3)

La EC2 debe poder ejecutar `aws s3 cp` o `aws s3 sync` **sin** pegar credenciales en el disco: se usa un **rol de instancia** (Instance profile).

### Paso 5.1 — Crear la política de solo lectura (o lectura acotada)

Similar al JSON anterior, pero **solo lectura** para lo que la EC2 necesita descargar:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::BUCKET_NAME"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": [
        "arn:aws:s3:::BUCKET_NAME/releases/*",
        "arn:aws:s3:::BUCKET_NAME/proyecto/*"
      ]
    }
  ]
}
```

Ajusta prefijos según cómo organices los objetos.

### Paso 5.2 — Crear el rol y asociarlo a la EC2

1. **IAM** → **Roles** → **Create role** → **Trusted entity type:** **AWS service** → **EC2**.
2. Adjunta la política anterior.
3. Nombre del rol: ej. `ec2-s3-deploy-read`.
4. En el asistente de **Launch Instance** (siguiente sección), en **Advanced details** → **IAM instance profile**, elige este rol **antes** de lanzar, o en la instancia ya creada: **Actions** → **Security** → **Modify IAM role**.

### Paso 5.3 — Comprobar desde la EC2

Tras instalar AWS CLI (sección 7), conéctate por SSH y ejecuta:

```bash
aws sts get-caller-identity
aws s3 ls s3://BUCKET_NAME/releases/
```

Si listas sin error, el rol está bien enlazado.

---

## 6. Crear la instancia EC2 y Security Group

### 6.1 — Security Group

1. **EC2** → **Security Groups** → **Create security group**.
2. **Inbound rules:**
   - **SSH (22):** origen **Mi IP** (recomendado) o el rango VPN de tu universidad. Evita `0.0.0.0/0` salvo pruebas muy breves.
   - **HTTP (80):** origen `0.0.0.0/0` si publicarás el front en el puerto 80 del host (`FRONTEND_PORT=80` en `.env`).
   - Si usas otro puerto (ej. 8080), añade una regla **Custom TCP** para ese puerto.
3. **Outbound rules:** por defecto suele permitir todo el tráfico saliente (necesario para `apt`, Docker Hub para imágenes base como `mysql:8.0-debian`, `node:18-alpine`, etc.).

**No** abras el puerto **3306** desde Internet.

### 6.2 — Lanzar la instancia

1. **EC2** → **Launch instance**.
2. **Name:** ej. `isy1101-docker-host`.
3. **AMI:** **Ubuntu Server 22.04 LTS** o **24.04 LTS**, arquitectura **64-bit (x86)** (coincide con builds típicos).
4. **Instance type:** mínimo recomendado **t3.small** (construir Java + Node en la EC2 consume CPU y RAM; **t3.micro** a menudo falla por memoria).
5. **Key pair:** elige o crea un par y descarga el `.pem`.
6. **Network settings:** elige tu VPC/subred pública si quieres IP pública, y el Security Group anterior.
7. **Configure storage:** 30 GiB gp3 o más (imágenes Docker y capas de build ocupan espacio).
8. **Advanced details** → **IAM instance profile:** el rol del apartado 5.
9. **Launch instance**.

Anota la **IP pública** o el **DNS público** (para SSH y para abrir el navegador).

---

## 7. Preparar la EC2: Docker, AWS CLI y carpetas

Conéctate (Windows PowerShell o Git Bash; ajusta ruta y usuario):

```bash
ssh -i "C:\ruta\a\tu-clave.pem" ubuntu@TU_IP_PUBLICA
```

### 7.1 — Actualizar el sistema e instalar paquetes

```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y docker.io docker-compose-plugin awscli unzip
```

### 7.2 — Permitir usar Docker sin sudo

```bash
sudo usermod -aG docker "$USER"
```

**Cierra la sesión SSH y vuelve a entrar** para que el grupo `docker` aplique.

Comprueba:

```bash
docker --version
docker compose version
aws --version
```

### 7.3 — Estructura de directorios en el servidor

```bash
sudo mkdir -p /opt/isy1101/repo
sudo chown -R "$USER:$USER" /opt/isy1101
```

- **`/opt/isy1101/repo`:** aquí irá el contenido descargado desde S3 (debe existir `docker-compose.yml` y la carpeta `proyecto semestral/` dentro de `repo` después de descomprimir o sincronizar).
- **`/opt/isy1101/.env`:** lo creas tú en la sección 8 (no viene del bucket).

---

## 8. Archivo `.env` en el servidor (obligatorio)

En la EC2, crea el archivo (usa un editor, ej. `nano`):

```bash
nano /opt/isy1101/.env
```

Contenido mínimo de ejemplo (**cambia todas las contraseñas**):

```env
# MySQL (deben coincidir con lo que espera docker-compose.yml)
DB_ROOT_PASSWORD=CambiarPorClaveRootLarga123!
DB_NAME=proyecto_db
DB_USER=appuser
DB_PASSWORD=CambiarPorClaveAppLarga456!

# Puerto del HOST donde Nginx del frontend escucha (80 típico)
FRONTEND_PORT=80

# Spring
SPRING_PROFILES_ACTIVE=production
```

Guarda (`Ctrl+O`, Enter, `Ctrl+X` en nano).

Restringe permisos del archivo:

```bash
chmod 600 /opt/isy1101/.env
```

Puedes tomar más variables de la plantilla **`.env.example`** en la raíz del repositorio (no subas el `.env` real a Git ni a S3).

---

## 9. Subir el proyecto al bucket (tres formas)

La raíz que debe quedar en `repo/` es la del repositorio: debe existir **`docker-compose.yml`** y la carpeta **`proyecto semestral/`** con los tres `Dockerfile`.

### 9.1 — Forma A: Consola web de S3 (arrastrar carpeta)

1. Entra al bucket → **Upload**.
2. Arrastra las carpetas/archivos necesarios. **Ojo:** mantener la misma estructura que en tu PC es tedioso; suele ser más práctico el ZIP (9.3) o `sync` (9.2).

### 9.2 — Forma B: `aws s3 sync` desde tu PC (carpeta)

En la raíz del proyecto en tu máquina (donde está `docker-compose.yml`), con AWS CLI ya configurado:

```bash
# Sincroniza el proyecto al prefijo "proyecto/" del bucket (sin borrar nada remoto extra)
aws s3 sync . s3://BUCKET_NAME/proyecto/ \
  --exclude ".git/*" \
  --exclude "*/node_modules/*" \
  --exclude "*/target/*" \
  --exclude ".cursor/*" \
  --exclude ".env"
```

**No subas** tu archivo local `.env` con contraseñas reales al bucket.

En la EC2, para bajar:

```bash
mkdir -p /opt/isy1101/repo
aws s3 sync s3://BUCKET_NAME/proyecto/ /opt/isy1101/repo/ --delete
```

**Advertencia:** `--delete` borrará en `repo/` lo que no esté en S3; por eso el `.env` está fuera en `/opt/isy1101/.env`.

### 9.3 — Forma C: ZIP manual desde tu PC

En la raíz del repo:

```bash
# Linux / macOS / Git Bash en Windows
zip -r deploy.zip . \
  -x "./.git/*" \
  -x "*/node_modules/*" \
  -x "*/target/*" \
  -x "./.cursor/*" \
  -x "./.env"
```

Sube el ZIP:

```bash
aws s3 cp deploy.zip s3://BUCKET_NAME/releases/manual.zip
```

En la EC2:

```bash
aws s3 cp s3://BUCKET_NAME/releases/manual.zip /tmp/deploy.zip
rm -rf /opt/isy1101/repo/*
unzip -o /tmp/deploy.zip -d /opt/isy1101/repo
```

---

## 10. Primera puesta en marcha en la EC2

Todos los comandos en la EC2, usuario con Docker en grupo `docker`.

### Paso 10.1 — Ir al directorio del código

```bash
cd /opt/isy1101/repo
```

Comprueba que exista:

```bash
ls -la docker-compose.yml
ls -la "proyecto semestral"
```

### Paso 10.2 — Construir imágenes y levantar contenedores

La primera vez puede tardar **varios minutos** (Maven, npm, imágenes base).

```bash
docker compose --env-file /opt/isy1101/.env -f docker-compose.yml build
docker compose --env-file /opt/isy1101/.env -f docker-compose.yml up -d
```

### Paso 10.3 — Comprobar estado

```bash
docker compose --env-file /opt/isy1101/.env -f docker-compose.yml ps
```

Todos los servicios deberían aparecer `running` o `healthy` tras unos segundos.

### Paso 10.4 — Probar en el navegador

Abre `http://TU_IP_PUBLICA` (o `http://TU_IP_PUBLICA:PUERTO` si `FRONTEND_PORT` no es 80).

---

## 11. Despliegue con GitHub Actions (ZIP → S3 → EC2)

El archivo **`.github/workflows/deploy-ec2.yml`** en este repositorio automatiza:

1. Empaquetar el código (excluyendo `.git`, `node_modules`, `target`, etc.).
2. Subir el ZIP a `s3://<BUCKET>/releases/<sha>.zip` y `s3://<BUCKET>/releases/latest.zip`.
3. Conectarse por SSH a la EC2, descargar `latest.zip`, descomprimir en `/opt/isy1101/repo` y ejecutar `docker compose build` + `up -d`.

### 11.1 — Secretos necesarios en GitHub

**Settings → Secrets and variables → Actions → Secrets:**

| Secreto | Descripción |
|---------|-------------|
| `AWS_ACCESS_KEY_ID` | Access key del usuario IAM con permiso de escritura en `releases/*` del bucket (salvo que migres a OIDC). |
| `AWS_SECRET_ACCESS_KEY` | Secret asociado. |
| `S3_BUCKET` | Nombre del bucket (ej. `isy1101-proyecto-guerb-2026`). |
| `EC2_HOST` | IP o DNS público de la EC2. |
| `EC2_USERNAME` | `ubuntu` o `ec2-user`. |
| `EC2_SSH_KEY` | Contenido completo de la clave privada `.pem`. |

**Variables (recomendado):** **Settings → Variables → Actions**

| Variable | Ejemplo | Uso |
|----------|---------|-----|
| `AWS_REGION` | `us-east-1` | Región del bucket y de `configure-aws-credentials`. |

Si no defines `AWS_REGION`, el workflow usa por defecto `us-east-1` (cámbialo en el YAML si tu bucket está en otra región).

### 11.2 — Requisitos en la EC2 antes del primer workflow

- Docker y plugin Compose instalados (sección 7).
- Rol IAM con `s3:GetObject` en `releases/*` (sección 5).
- `/opt/isy1101/.env` creado (sección 8).
- Carpeta `/opt/isy1101/repo` (el workflow puede crearla; si falla, créala a mano).
- Security Group permite **SSH desde la IP del runner de GitHub** **o** desde tu red si ejecutas el workflow manualmente desde un entorno que use self-hosted runner; en la práctica muchos equipos abren SSH temporalmente a `0.0.0.0/0` solo en laboratorio (no recomendado en producción). La alternativa robusta es **AWS SSM Session Manager** sin puerto 22 público (fuera del alcance de esta guía breve).

### 11.3 — Ejecutar el workflow

**Actions → Deploy to EC2 (S3 + build en servidor) → Run workflow**.

El job tiene un **timeout largo** para `docker compose build` en la EC2. Si falla por tiempo, aumenta `command_timeout` en el YAML o usa una instancia más grande.

---

## 12. Actualizar la aplicación (ciclos posteriores)

1. Sube código nuevo al bucket (sync, ZIP manual, o workflow).
2. En la EC2:

```bash
cd /opt/isy1101/repo
# Opción sync:
# aws s3 sync s3://BUCKET/proyecto/ . --delete

# Opción ZIP (latest):
aws s3 cp s3://BUCKET/releases/latest.zip /tmp/latest.zip
rm -rf /opt/isy1101/repo/*
unzip -o /tmp/latest.zip -d /opt/isy1101/repo

docker compose --env-file /opt/isy1101/.env -f docker-compose.yml build
docker compose --env-file /opt/isy1101/.env -f docker-compose.yml up -d
```

3. Si solo cambió configuración en `.env`, basta con:

```bash
docker compose --env-file /opt/isy1101/.env -f docker-compose.yml up -d
```

---

## 13. Verificación y diagnóstico

```bash
cd /opt/isy1101/repo
docker compose --env-file /opt/isy1101/.env -f docker-compose.yml ps
docker compose --env-file /opt/isy1101/.env -f docker-compose.yml logs -f --tail=80 frontend
docker compose --env-file /opt/isy1101/.env -f docker-compose.yml logs -f --tail=80 api-ventas
```

Desde tu PC (opcional), comprobar salud del front si el puerto está mapeado:

```bash
curl -sI http://TU_IP_PUBLICA/health
```

---

## 14. Problemas frecuentes y soluciones

| Problema | Causa probable | Qué hacer |
|----------|-----------------|------------|
| `Access Denied` al hacer `aws s3` en la EC2 | Sin rol IAM o política incorrecta | Revisa el rol adjunto a la instancia y el ARN del bucket/prefijo en la política. |
| `docker: permission denied` | Usuario no está en el grupo `docker` | `sudo usermod -aG docker $USER` y nueva sesión SSH. |
| Build Java OOM / proceso muerto | Instancia muy pequeña | Sube a **t3.small** o **t3.medium**; cierra otros procesos. |
| `Schema-validation` o tablas faltantes | BD vacía con `validate` | En `docker-compose.yml` las APIs usan `update` en variables de entorno; revisa `.env` y logs de MySQL. |
| Navegador no carga | SG o puerto | Abre el puerto de `FRONTEND_PORT` en el Security Group; comprueba `ufw status` en Ubuntu. |
| SSH del workflow falla | IP del runner bloqueada | Ajusta reglas SSH o usa runner self-hosted en la misma red. |
| `unzip: command not found` | Paquete no instalado | `sudo apt-get install -y unzip`. |

---

## 15. Anexo: despliegue con registro Docker (opcional)

Si más adelante quieres **no** compilar en la EC2 y solo hacer `docker compose pull`, puedes usar el archivo **`docker-compose.prod.yml`** del repositorio (pensado para imágenes en Docker Hub u otro registro) y los workflows **Build & Publish** existentes. Ese flujo es independiente del flujo S3 descrito en las secciones anteriores.

---

## Resumen ultra corto (checklist)

1. Crear bucket S3 (privado, cifrado).  
2. IAM: usuario/clave o rol para **subir** a `releases/`; rol EC2 para **leer**.  
3. EC2 Ubuntu, SG (22 acotado, 80 u otro para web), rol IAM, disco ≥ 30 GiB, **t3.small+**.  
4. Instalar Docker, Compose plugin, AWS CLI, `unzip`; carpetas `/opt/isy1101` y `repo`.  
5. Crear `/opt/isy1101/.env` (nunca subir secretos al bucket).  
6. Subir código al bucket (sync o ZIP).  
7. En EC2: descomprimir/sync a `repo`, `docker compose --env-file /opt/isy1101/.env build && up -d`.  
8. (Opcional) GitHub Actions con secretos `AWS_*`, `S3_BUCKET`, `EC2_*` para automatizar ZIP → S3 → EC2.
