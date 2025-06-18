# 🗳️ Obligatorio Voting App

## 🛠️ Herramientas
- **Repositorio:** GitHub  
- **CI/CD:** GitHub Actions  
- **Análisis de código estático:** SonarQube  
- **Cloud:** AWS  
- **Infraestructura como Código (IaC):** Terraform  
- **Testing:** JMeter  

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





## 🚧 CodeQL y  super-linter como *Quality Gate* en el Proceso de Integración Continua

Este repositorio utiliza [`codeql-analysis.yml`](.github/workflows/codeql-analysis.yml) para configurar y ejecutar [CodeQL](https://codeql.github.com/), una herramienta de análisis de código estático desarrollada por GitHub, para los siguientes lenguajes 'csharp', 'javascript', 'python'. En este caso, se aplica específicamente a la aplicación `voting-app`, con el objetivo de detectar automáticamente vulnerabilidades, errores y problemas de calidad en el código de sus distintos servicios.
En este repositorio, CodeQL se utiliza como un **_quality gate_ automático** durante el proceso de integración continua. Esto garantiza que el código que se fusiona en las ramas principales (`dev`, `test` y `prod`) haya pasado un análisis de seguridad y calidad.

### 🔁 Flujo de trabajo

1. **Creación de un Pull Request hacia `dev`, `test` o `prod`**
   - Cada vez que se propone un cambio hacia alguna de estas ramas, se activa automáticamente un análisis CodeQL a través de GitHub Actions.

2. **Ejecución del análisis de seguridad**
   - CodeQL analiza el código fuente, construye una base de datos interna y ejecuta consultas para detectar:
     - Vulnerabilidades de seguridad
     - Errores de lógica
     - Problemas comunes de codificación

3. **Evaluación del resultado**
   - Si el análisis detecta alertas críticas, el workflow falla y **se bloquea el merge** hasta que se resuelvan los problemas.

4. **Merge aprobado solo si pasa el quality gate**
   - El código solo puede integrarse si pasa exitosamente el análisis CodeQL, asegurando que las ramas clave mantengan un nivel mínimo de seguridad y calidad.

### ✅ Beneficios

- 🔒 **Seguridad preventiva**: Se bloquean vulnerabilidades antes de llegar a producción.
- 📐 **Consistencia**: Se aplica el mismo estándar en todos los entornos (`dev`, `test`, `prod`).
- 🧹 **Reducción de deuda técnica**: Se previene la acumulación de errores y malas prácticas en el tiempo.
- 🚀 **Despliegues más confiables**: Cada rama mantiene un estado seguro y controlado.

---

📌 *EXTRA* Este proceso se complementa con la configuración de **branch protection rules** en GitHub, exigiendo que el análisis CodeQL se complete correctamente antes de permitir merges en las ramas protegidas.

---
Las configuraciones de las **branch protection rules** son las siguientes:

![QG_1.png](QG_1.png)

![QG_2.png](QG_2.png)

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
