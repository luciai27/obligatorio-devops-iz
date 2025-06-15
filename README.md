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

🛠️ Diagrama de Flujo - Build & Push a ECR (Voting App)
```text
Inicio
└── 🔹 Push a rama (dev, test, main)
    └── 🟩 Determinar entorno
        ├── dev → entorno desarrollo
        ├── test → entorno testing
        └── main → entorno producción
            └── 🟨 Login a AWS/ECR
                ├── aws ecr get-login-password
                └── docker login con el token generado
                    └── 🟧 Generar tag único
                        ├── Obtener hash corto del commit (GIT_COMMIT)
                        └── Formato: voting-app:<ambiente>-<GIT_COMMIT>
                            └── 🟦 Construcción de imagen
                                └── docker build -t voting-app:<tag> .
                                    └── 🟩 Subir imagen a ECR
                                        ├── docker tag → apuntar al repo ECR
                                        └── docker push → subir imagen
                                            └── 📝 Actualizar archivo docker-compose.generated.yml
                                                ├── Reemplazar tag de imagen
                                                └── Guardar archivo actualizado
                                                    └── ✅ Fin
                                                        ├── Imagen disponible en ECR
                                                        └── Archivo listo para despliegue


```

 ## Terraform Deploy
   - Se ejecuta Terraform desde GitHub Actions apuntando al ambiente correspondiente:
     - `dev` → subnet `192.168.2.0/24` + pública `192.168.12.0/24`
     - `test` → subnet `192.168.3.0/24` + pública `192.168.13.0/24`
     - `main` → subnet `192.168.1.0/24` + pública `192.168.11.0/24`
   - Se usa `docker-compose.generated.yml` del S3 para levantar la app

 ## Análisis estático 
   - Se ejecuta SonarQube en cada push para evaluar calidad de código
   - Se usa el GitHub Action oficial de SonarCloud o configuración personalizada con `sonar-scanner`

   #### Prerrequisitos SonarQube:
   - Tener un proyecto creado en [SonarCloud](https://sonarcloud.io/) o en tu instancia propia de SonarQube
   - Generar un `SONAR_TOKEN` y agregarlo como *Secret* en GitHub
   - Configurar el archivo `sonar-project.properties` en la raíz del repo, por ejemplo:

     ```properties
     sonar.projectKey=nombre-del-proyecto
     sonar.organization=nombre-organizacion
     sonar.host.url=https://sonarcloud.io
     sonar.login=${SONAR_TOKEN}
     sonar.sources=.
     sonar.language=js
     sonar.sourceEncoding=UTF-8
     ```

   - Verificar que las rutas (`sonar.sources`) coincidan con el código fuente real

## Testing
   - Se ejecutan pruebas de carga con JMeter sobre el entorno correspondiente

## Notificación
   - Se envía un correo a `$REPO_OWNER_MAIL` con resultados del pipeline y link al despliegue

## 🔐 Análisis de Seguridad Automatizado con CodeQL

Este repositorio utiliza [`codeql-analysis.yml`](.github/workflows/codeql-analysis.yml) para configurar y ejecutar [CodeQL](https://codeql.github.com/), una herramienta de análisis de código estático desarrollada por GitHub. En este caso, se aplica específicamente a la aplicación `voting-app`, con el objetivo de detectar automáticamente vulnerabilidades, errores y problemas de calidad en el código de sus distintos servicios.

### Utilizamos CodeQL en `voting app`:

- ⚙️ **Automatización del análisis de seguridad**  
  CodeQL se ejecuta automáticamente en cada cambio del código (_push_, _pull request_, etc.), asegurando una validación continua del repositorio.

- 🛡️ **Detección temprana de vulnerabilidades**  
  Analiza el código de los servicios `vote`, `result`, `worker`, `redis` y `db` para identificar posibles fallas de seguridad antes de que lleguen a producción.

- 🧹 **Mejora de la calidad del código**  
  CodeQL no solo busca vulnerabilidades sino también errores lógicos y problemas de estilo, ayudando a mantener un código limpio y robusto.

- 🧩 **Flexibilidad y personalización**  
  Se pueden definir consultas personalizadas para adaptarse al diseño modular y a las particularidades de la arquitectura de `voting-app`.

- 🔄 **Integración con GitHub Actions**  
  El análisis se realiza automáticamente como parte del flujo de integración continua con [GitHub Actions](https://docs.github.com/en/actions), sin intervención manual.

- 👁️ **Visibilidad clara de los resultados**  
  Las alertas generadas por CodeQL aparecen en la pestaña **Security** de GitHub, lo que facilita su seguimiento por parte del equipo de desarrollo.

### 🧪 ¿Cómo funciona?

1. **Definición del flujo de trabajo**  
   El archivo `codeql-analysis.yml` configura la ejecución de CodeQL para los lenguajes utilizados en `voting-app` (por ejemplo, Python y JavaScript).

2. **Creación de la base de datos CodeQL**  
   Se analiza el código fuente de cada servicio y se construye una base de datos con su estructura y semántica.

3. **Ejecución de consultas**  
   Se aplican consultas predefinidas y, si es necesario, personalizadas, para identificar vulnerabilidades y errores en los servicios de la aplicación.

4. **Publicación de resultados**  
   Las alertas se muestran automáticamente en GitHub, brindando a los desarrolladores información detallada para remediarlas.

---

👉 Más información sobre CodeQL: [https://codeql.github.com/docs/](https://codeql.github.com/docs/)

---
