# 🗳️ Obligatorio Voting App

## 🛠️ Herramientas
- **Repositorio:** GitHub  
- **CI/CD:** GitHub Actions  
- **Análisis de código estático:** SonarQube  
- **Cloud:** AWS  
- **Infraestructura como Código (IaC):** Terraform  
- **Testing:** JMeter  

---

## 🌿 Estrategia Git Flow

La estrategia elegida fue **Git Flow**. Si bien entendemos que la estrategia **Trunk Based** tiene características útiles (promueve integración continua, especialmente útil en proyectos pequeños), decidimos utilizar **Git Flow** ya que nos permite observar más atentamente los cambios realizados a la rama principal.

Dado que todavía estamos aprendiendo cómo utilizar las tecnologías enseñadas en clase, consideramos que un monitoreo más a fondo de lo que se incorpora es la estrategia que más se alinea con nuestra forma de trabajo. Al utilizar esta estrategia, sabemos que lo que se integra a la rama `main` está funcionando correctamente.

### ✅ Entornos bien definidos y separados
El proyecto tiene ramas bien diferenciadas que se alinean con Git Flow:
- `develop`: para desarrollo
- `test`: para validación antes de producción
- `main`: versión estable y en producción

### 📦 Control sobre versiones y despliegues
Git Flow permite:
- Controlar cuándo se libera una nueva versión
- Aplicar hotfixes sin afectar `develop`
- Mantener la estabilidad en `main` mientras se desarrollan nuevas funcionalidades

### 🔁 Integración con flujos CI/CD por ramas
- La app genera imágenes por rama (`dev`, `test`, `main`)
- Cada rama despliega en su entorno específico
- Git Flow encaja naturalmente con pipelines CI/CD basados en tags por rama

### 🛡️ Aislación de features y bugs
- Ramas específicas para nuevas features sin romper `develop`
- Hotfixes críticos directamente sobre `main`
- Mayor seguridad antes de llegar a producción

---

## 🔐 Prerequisitos
Estas variables deben estar configuradas como *Secrets* en GitHub:

- `AWS_ACCESS_KEY_ID`
- `AWS_REGION`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`
- `BUCKET_NAME` (nombre único del bucket S3)
- `EMAIL_USER`
- `EMAIL_PASS`
- `REPO_OWNER_MAIL`
- `SONAR_TOKEN`

---

## 📁 Estrategia de Repositorio para Infraestructura

Decidimos usar **el mismo repositorio** para la carpeta de infraestructura.  
Esto nos resulta más práctico para un proyecto pequeño como este, ya que podemos realizar cambios tanto en la aplicación como en la infraestructura desde un mismo lugar.  
Si el proyecto fuera más grande, sí consideraríamos separar el código de infraestructura en un repositorio exclusivo para facilitar su reutilización.

---

## 🧱 Arquitectura

![Architecture diagram](architecture.excalidraw.png)

Componentes:
- 🐍 Front-end en [Python](/vote): permite votar entre dos opciones
- 🧠 [Redis](https://hub.docker.com/_/redis/): almacena los votos temporales
- ⚙️ [Worker en .NET](/worker): consume votos desde Redis y los guarda en...
- 🛢️ [Postgres](https://hub.docker.com/_/postgres/): base de datos persistente
- 📊 Web app [Node.js](/result): muestra resultados de la votación en tiempo real

---

## 🚀 Flow de CI/CD

1. **Push a una rama (`dev`, `test`, `main`)**
   - Se genera una nueva imagen Docker con tag único
   - Se sube la imagen a ECR correspondiente al entorno
   - Se actualiza el archivo `docker-compose.generated.yml` con el tag generado
   - El archivo `docker-compose.generated.yml` se sube a un bucket S3
