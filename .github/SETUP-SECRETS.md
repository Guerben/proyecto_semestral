# ============================================================================
# GitHub Actions - Guía de Configuración de Secretos
# ============================================================================

## 🔑 ¿Qué son los Secrets?

Los Secrets de GitHub son valores encriptados que se almacenan de forma segura
y están disponibles para los workflows de GitHub Actions.

⚠️ **IMPORTANTE:** Los secrets NO aparecen en los logs de GitHub Actions por razones de seguridad.

---

## 📋 Secretos Necesarios

### 1️⃣ DOCKER_HUB_USERNAME
- **Descripción:** Tu nombre de usuario en Docker Hub
- **Ejemplo:** `tu-usuario`
- **Obligatorio:** Sí
- **Confidencial:** No (es público)

### 2️⃣ DOCKER_HUB_TOKEN
- **Descripción:** Personal Access Token de Docker Hub (NO contraseña)
- **Ejemplo:** `dckr_pat_xxxxxxxxxxxxxxxxxxxx`
- **Obligatorio:** Sí
- **Confidencial:** Sí ⚠️ (guardar bien)

---

## 🔧 Paso 1: Crear Personal Access Token en Docker Hub

### A. Ir a la página de seguridad de Docker Hub

1. Abre https://hub.docker.com/settings/security
2. Inicia sesión si es necesario

### B. Generar nuevo token

1. Clic en "New Access Token"
2. Dale un nombre descriptivo: `GitHub Actions`
3. Selecciona permisos:
   - ✅ **Read & Write**  (para push)
   - ✅ **Read**  (para pull)
4. Clic en "Generate"

### C. Copiar el token

⚠️ **IMPORTANTE:** El token solo aparecerá UNA VEZ
- Copia el token completo
- Guarda en lugar seguro
- NO lo compartas

---

## 🔒 Paso 2: Agregar Secrets a GitHub

### A. Acceder a Settings del repositorio

1. Abre tu repositorio en GitHub
2. Ve a **Settings** (pestaña)
3. En el menú izquierdo: **Secrets and variables > Actions**

### B. Agregar DOCKER_HUB_USERNAME

1. Clic en "New repository secret"
2. **Name:** `DOCKER_HUB_USERNAME`
3. **Value:** Tu usuario de Docker Hub (ejemplo: `tu-usuario`)
4. Clic en "Add secret"

### C. Agregar DOCKER_HUB_TOKEN

1. Clic en "New repository secret"
2. **Name:** `DOCKER_HUB_TOKEN`
3. **Value:** Pega el token que copiaste antes
4. Clic en "Add secret"

---

## ✅ Verificar Configuración

### Paso 1: Ver secrets configurados

En GitHub > Settings > Secrets and variables > Actions

Deberías ver:
```
DOCKER_HUB_TOKEN ●●●●●●●●●●●●●●●● (actualizado hace 5 min)
DOCKER_HUB_USERNAME ●●●●●●●●●●●●●●●● (actualizado hace 5 min)
```

### Paso 2: Probar el workflow

1. Haz un cambio pequeño en tu código
2. Haz `push` a `main` o `develop`
3. Ve a **Actions** en GitHub
4. Selecciona el workflow que se ejecutó
5. Verifica que pasó sin errores

### Paso 3: Verificar que la imagen se publicó

1. Ve a https://hub.docker.com/r/tu-usuario
2. Deberías ver tus imágenes:
   - `api-ventas`
   - `api-despachos`
   - `frontend`

---

## 🐛 Troubleshooting de Secrets

### ❌ Error: "Invalid username or personal access token"

**Causa:** Credenciales incorrectas

**Solución:**
1. Verifica que `DOCKER_HUB_USERNAME` es correcto
2. Genera un nuevo token en Docker Hub
3. Actualiza `DOCKER_HUB_TOKEN` con el nuevo valor

### ❌ Error: "Authentication failed"

**Causa:** El token no tiene permisos suficientes

**Solución:**
1. Ve a Docker Hub > Settings > Security
2. Revoca el token viejo
3. Crea nuevo token con permisos **Read & Write**

### ❌ Error: "Secret not found"

**Causa:** El nombre del secret es diferente en el workflow

**Solución:**
1. Verifica que el nombre en GitHub coincida con el workflow
2. Los nombres de secrets son **case-sensitive**
3. Ejemplo correcto: `DOCKER_HUB_TOKEN` (NO `docker_hub_token`)

### ❌ El workflow no se ejecuta

**Causa:** El workflow está deshabilitado o no hay trigger

**Solución:**
1. Ve a **Actions > (Tu workflow)**
2. Verifica que esté habilitado
3. Haz un cambio en los archivos del workflow para forzar ejecución:
   ```bash
   git commit --allow-empty -m "Trigger workflow"
   git push
   ```

### ❌ Las imágenes no aparecen en Docker Hub

**Causa:** El push no se ejecutó o falló

**Solución:**
1. Ve a **Actions > Build & Publish**
2. Haz clic en la ejecución que falló
3. Busca el paso "Build Docker image"
4. Lee los logs para ver el error específico
5. Corrige y vuelve a intentar

---

## 🔄 Usar Secrets en Workflows

Los secretos se usan en workflows así:

```yaml
- name: Login to Docker Hub
  uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKER_HUB_USERNAME }}
    password: ${{ secrets.DOCKER_HUB_TOKEN }}
```

**Notas:**
- Los secrets **NO aparecen en los logs** (reemplazados por `***`)
- Acceso: `${{ secrets.NOMBRE_DEL_SECRET }}`
- Case-sensitive: `${{ secrets.Docker_Hub_Token }}` ≠ `${{ secrets.DOCKER_HUB_TOKEN }}`

---

## 🛡️ Mejores Prácticas de Seguridad

### ✅ HAGO

- ✅ Usar Personal Access Token (no contraseña)
- ✅ Limitar permisos del token (solo lo necesario)
- ✅ Rotar tokens regularmente (cada 3-6 meses)
- ✅ Guardar tokens en lugar seguro
- ✅ Usar GitHub Secrets (encriptados)
- ✅ Revocar tokens antiguos

### ❌ NUNCA HAGO

- ❌ Guardar tokens en archivos (`.env`, `config.yml`)
- ❌ Commitear archivos con tokens
- ❌ Compartir tokens por email o chat
- ❌ Usar contraseña en lugar de token
- ❌ Dejar tokens sin expiración
- ❌ Reutilizar tokens en múltiples sistemas

---

## 📝 Checklist de Configuración

- [ ] Token de Docker Hub generado
- [ ] `DOCKER_HUB_USERNAME` agregado a GitHub Secrets
- [ ] `DOCKER_HUB_TOKEN` agregado a GitHub Secrets
- [ ] Workflow ejecutado con éxito
- [ ] Imagen apareció en Docker Hub
- [ ] Verificar que imagen se puede descargar: `docker pull tu-usuario/api-ventas`

---

## 🔗 Referencias

- [Docker Hub Personal Access Tokens](https://docs.docker.com/docker-hub/access-tokens/)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

**¿Necesitas ayuda?**
- 📖 Ver [`DOCKER-GUIA-COMPLETA.md`](./DOCKER-GUIA-COMPLETA.md)
- 📧 Email: soporte@citt.cl
- 🐛 GitHub Issues: [Crear issue](../../issues/new)
