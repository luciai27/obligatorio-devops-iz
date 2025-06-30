# 🗳️ Obligatorio Voting App

## 🛠️ Herramientas
- **Repositorio:** GitHub  
- **CI/CD:** GitHub Actions  
- **Análisis de código estático:** SonarQube  
- **Cloud:** AWS
- **Orquestador:** EKS
- **Repositorio:** ECR
- **Infraestructura como Código (IaC):** Terraform  
- **Testing:** JMeter
- **Serverless:** Lambda 

---
## 🔐 Prerequisitos
Estas variables deben estar configuradas como *Secrets* en GitHub:

- `AWS_ACCESS_KEY_ID`
- `AWS_REGION`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`
- `BUCKET_NAME` (nombre único del bucket S3 en donde se guardarán los tfstates.)
- `EMAIL_USER`
- `EMAIL_PASS`
- `REPO_OWNER_MAIL`
- `SONAR_TOKEN`

Los primeros cuatro secretos corresponden a configuraciones de AWS, por lo que siempre son necesarios para poder acceder correctamente a los servicios.

El Bucket Name es necesario ya que, al ser dos personas las que estamos trabajando en el proyecto y dado que los buckets de S3 deben tener nombres únicos, no es posible utilizar un mismo nombre en cuentas diferentes. Esto fue algo que se tuvo que parametrizar (y, por lo tanto, el mismo debe ser creado manualmente **antes** de correr el pipeline).

Los secretos de Email User, Email Pass y Repo Owner Mail son necesarios para el envío de correo cuando se crea un Pull Request y cuando finaliza lambda.

El Sonar Token es necesario para la realización del análisis de código de SonarQube.


---

## 🌿 Estrategia Git Flow

La estrategia elegida fue **Git Flow**. Si bien entendemos que la estrategia **Trunk Based** tiene características útiles (promueve integración continua, especialmente útil en proyectos pequeños), decidimos utilizar **Git Flow** ya que nos permite observar más atentamente los cambios realizados a la rama principal.

Dado que todavía estamos aprendiendo cómo utilizar las tecnologías enseñadas en clase, consideramos que un monitoreo más a fondo de lo que se incorpora a la rama principal es la estrategia que más se alinea con nuestra forma de trabajo. Al utilizar esta estrategia, sabemos que lo que se integra a `main` está funcionando correctamente.

### ✅ Entornos bien definidos y separados
El proyecto tiene ramas bien diferenciadas que se alinean con Git Flow:
- `dev`: para desarrollo
- `test`: para validación antes de producción
- `main`: versión estable y en producción

### 📦 Control sobre versiones y despliegues
Git Flow permite:
- Controlar cuándo se libera una nueva versión
- Aplicar hotfixes sin afectar `dev`
- Mantener la estabilidad en `main` mientras se desarrollan nuevas funcionalidades

### 🔁 Integración con flujos CI/CD por ramas
- La app genera imágenes por rama (`dev`, `test`, `main`)
- Cada rama despliega en su entorno específico
- Git Flow encaja naturalmente con pipelines CI/CD basados en tags por rama

### 🛡️ Aislación de features y bugs
- Ramas específicas para nuevas features sin romper `dev`
- Hotfixes críticos directamente sobre `main`
- Mayor seguridad antes de llegar a producción

---



## 📁 Estrategia de Repositorio para Infraestructura

Decidimos usar **el mismo repositorio** para la carpeta de infraestructura. 

Esto nos resulta más práctico para un proyecto pequeño como este, ya que podemos realizar cambios tanto en la aplicación como en la infraestructura desde un mismo lugar. Si el proyecto fuera más grande, sí consideraríamos separar el código de infraestructura en un repositorio exclusivo para facilitar su reutilización.

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
2. **Se configuran credenciales AWS**
3. **Se crean repositorios ECR para imágenes**
4. **Se genera una nueva imagen Docker con tag único**
5. **Se sube la imagen a ECR con tag de entorno**
6. **Se actualiza el archivo `docker-compose.generated.yml` con el tag generado**
7. **El archivo `docker-compose.generated.yml` se sube a bucket S3**
8. **Se crea la infraestructura común a todos los ambientes (network)**
9. **Se crea la infrastructura correspondiente al ambiente del push**
10. **Se remplazan variables y se despliegan manifiestos K8s**
11. **Se prepara ambiente para testing**
12. **Se buscan los URL de los ALBs y setean como variables**
13. **Se realiza testing de carga en ALBs creados por K8s (Vote y Result)**
14. **Se invoca función Lambda para verificación de estado de URLs**
15. **Se procesan resultados y se envía notificación por correo electrónico**

### 🛠️ Diagrama de Flujo - CI/CD Voting App

Se ilustra el flujo mencionado anteriormente mediante un diagrama: 

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
                        ├── obtener hash corto del commit (GIT_COMMIT)
                        └── Formato: voting-app:<ambiente>-<GIT_COMMIT>
                            └── 🟦 Construcción de imágenes
                                └── docker build -t voting-app:<tag> .
                                    └── 🟩 Subir imagen a ECR
                                        ├── docker tag → apuntar al repo ECR
                                        └── docker push → subir imagen
                                            └── 📝 Actualizar archivo docker-compose.generated.yml
                                                ├── reemplazar tag de imagen
                                                └── guardar archivo actualizado
                                                    └── ✅ Archivo listo para despliegue
                                                        └── imagen disponible en ECR
                                                            └── 🟦 Creación de infra con Terraform
                                                                ├── terraform init y apply: capa network
                                                                ├── tfstate network guardado en bucket
                                                                ├── terraform init y apply: capa ambiente actual
                                                                └── tfstate ambiente guardado en bucket
                                                                    └── 🟩 Despliegue de Kubernetes
                                                                        ├── reemplazo de variables en manifiestos
                                                                        ├── aws eks update-kubeconfig
                                                                        └── kubectl apply -f k8s-specifications
                                                                            └── 🔍 Seteo de ambiente y config para Testing
                                                                                └── 🟨 Obtención de URL de ALBs
                                                                                    ├── busca por puerto 8080
                                                                                    ├── setea dependiendo del ambiente
                                                                                    ├── busca por puerto 8081
                                                                                    └── setea dependiendo del ambiente
                                                                                         └──🔍 Corre testing               
                                                                                            ├── carga para ALB vote
                                                                                            ├── carga para ALB result
                                                                                            └── QG: pasa si success = %100
                                                                                                └──λ Invocar Lambda con ALBs
                                                                                                    ├── check URL vote OK
                                                                                                    └── check URL result OK
                                                                                                        └── 📧 Email notification de lambda result
                                                                                                            └── 📧 Email notification Resultado del Pipeline


```

 ## 🏛 Terraform Deploy
   - La estructura de infraestructura es la siguiente
   ```text  
        infra/
            env
              |_ dev 
              |    lambda_backup.tf
              |    main.tf
              |    outputs.tf
              |    terraform.tfvars
              |    variables.tf    
              |_ test
              |    lambda_backup.tf
              |    main.tf
              |    outputs.tf
              |    terraform.tfvars
              |    variables.tf    
              |_ main
              |    lambda_backup.tf
              |    main.tf
              |    outputs.tf
              |    terraform.tfvars
              |    variables.tf
            network
                 main.tf
                 output.tf

   
```
Tomamos la decisión de esta estructura para la infraestructura por los siguientes motivos:

☀ **Separación clara por entorno**

Cada entorno (dev, test, main) tiene su propio conjunto de archivos Terraform:
   - Permite aplicar cambios de forma independiente.
   - Reduce el riesgo de errores al evitar que cambios en desarrollo afecten producción.
   - Facilita pruebas y validaciones antes de promover cambios.
     
🔃 **Reutilización**
 
 La carpeta network define infraestructura en común para todos los ambientes, VPC, IGW, etc. 

↗ **Escalabilidad**
 
 Es facilmente escalable, se puede agregar nuevos entornos sin modificar los existintes

💭 **Gestión de variables por entorno**

 Cada entorno tiene su propio terraform.tfvars, permite definir configuraciones específicas (nombres, tamaños, regiones, etc.) sin duplicar lógica, mejora la trazabilidad y el control de cambios.
 
📑 **Cumplimiento y auditoría**

 Separar entornos ayuda a cumplir con políticas de seguridad y auditoría.

👔 **Prácticas Devops**
 
 Se tomaron en consideración las prácticas más comunes de Devops. Cada ambiente tiene su propio cluster EKS (en vez de tener un solo cluster con tres namespaces).

---

📌 *EXTRA* Además con esta estructura podemos automatizar despliegues por entorno.

---
 ## ☸️ Orquestador
 
 Se eligió Amazon Elastic Kubernetes Service (EKS) por las siguientes razones:

**✅ Escalabilidad automática**

EKS permite escalar dinámicamente pods y nodos según la carga, garantizando que servicios como vote o result puedan atender picos de tráfico sin intervención manual.

**🔐 Alta disponibilidad y seguridad**

Al estar distribuido entre zonas de disponibilidad (AZs) y con integración a IAM, EKS asegura resiliencia y un control de acceso robusto a los recursos del clúster.

**⚙️ Automatización del despliegue (CI/CD)**

La infraestructura de EKS se integra perfectamente con pipelines CI/CD (como GitHub Actions), lo que facilita el despliegue continuo de contenedores con comandos como kubectl apply.

**🔁 Rolling updates sin downtime**

Kubernetes permite realizar actualizaciones de los servicios de forma progresiva, manteniendo siempre al menos una instancia operativa, lo que evita interrupciones en producción.

**📦 Diseño contenerizado natural**

La Voting App está dividida en servicios como vote, result, db, worker y redis, cada uno en su propio contenedor, lo que encaja perfectamente con el modelo de despliegue en Kubernetes.

**☁️ Integración nativa con AWS**

EKS facilita el uso de otros servicios como S3 (almacenamiento), CloudWatch (monitoreo), Load Balancers (exposición de servicios), Lambda (verificación de estado) y más, sin configuración extra compleja.

![EKS_arquitectura.png](/IMG/EKS_arquitectura.png)

 ## 🔧 ECR Amazon Elastic Container Registry

 Se utilizó Amazon Elastic Container Registry (ECR) como repositorio privado para almacenar las imágenes Docker generadas en el pipeline por los siguientes motivos:

🥇 **Integración nativa con EKS**
 
 Permite que los pods del clúster descarguen imágenes directamente desde ECR sin configuración adicional.

🔐 **Seguridad y control de acceso**
 
 ECR se integra con IAM para definir políticas de acceso seguras para subir, listar o descargar imágenes.

▶ **Automatización con CI/CD**
 
 Es compatible con GitHub Actions y facilita el versionado automático de imágenes por rama (dev, test, main).

✅ **Alto rendimiento y disponibilidad**
 
 Al estar alojado en AWS, garantiza disponibilidad y baja latencia en la entrega de imágenes a los nodos EKS.

 🏠 **Sin necesidad de configurar y mantener un registry externo**
 
 Evita complejidad operativa y costos de autohospedar un registry.

 Las imagenes se suben con un tag, en la cual se le llama TAG_COMBINADO, se genera en el script build-and-push.sh, TAG_COMBINADO="$BRANCH_TAG-$COMMIT_HASH", se almacene en el registry de aws.

 En esta dos linea es donde se indica la creacion del ECR, de forma automatica:
 
 ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
 
 ECR_BASE_URL="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

 ## 📖 Análisis estático 
   - Se ejecuta SonarQube en cada push para evaluar calidad de código
   - Se usa el GitHub Action oficial de SonarCloud o configuración personalizada con `sonar-scanner`
   - SonarQube permite mejorar la calidad del código automáticamente al analizarlo en busca de errores, vulnerabilidades, código duplicado y malas prácticas. Facilita el mantenimiento, reduce el riesgo de fallos en producción y promueve buenas prácticas de desarrollo mediante métricas claras e integraciones con            CI/CD. Además, ayuda a asegurar que el código nuevo  no degrade la calidad existente.

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

 ### Infrome de sonarQube

![Informe_SonarQube.docx](/IMG/Informe_SonarQube.docx)

---

## 🐞 Testing
Para la realización del testing del obligatorio se optó por pruebas de carga utilizando JMeter. Se usó BlazeMeter con Taurus, lo que permitió incluir un failure criteria.
La prueba de carga que se realizó se encuentra en el archivo test.jmx y consiste en lo siguiente:

- `<intProp name="ThreadGroup.num_threads">10</intProp>`: el número de threads (usuarios) es 10.
- `<intProp name="ThreadGroup.ramp_time">5</intProp>`: JMeter demora 5 segundos para que se conecten los 10 usuarios.
- `<longProp name="ThreadGroup.duration">15</longProp>`: la duración total del test es de 15 segundos.
- Cada usuario ejecutará la solicitud HTTP tan rápido como sea posible hasta que hayan transcurrido los 15 segundos.

En el pipeline de CI/CD se incluyó la linea "-o reporting='[{"module": "passfail", "criteria": ["succ<100%,stop as failed"]}]'", que fue lo que nos permitió forzar el rompimiento del pipeline si alguna de las pruebas lograba un resultado insatisfactorio (cualquier cosa menor que 100% success). Dado que el flujo no sigue si el test falla, el mismo consituyó otra **Quality Gate**.

---

## 🟢 Lambda url-checker 

**Verificación de disponibilidad de servicios**

Esta función Lambda fue desarrollada con el objetivo de monitorear la disponibilidad de los servicios frontend de la Voting App desplegados en AWS (por ejemplo, las aplicaciones vote y result publicadas detrás de ALBs).

 ```
/lambda
   |_lambda.zip
 ```

Algunas caracterísitcas son:
- Se invoca automáticamente desde el pipeline de CI/CD en GitHub Actions, luego del despliegue de infraestructura y servicios, para verificar que las URLs estén accesibles y respondiendo correctamente.
- Permite detectar errores tempranos en el pipeline si algún servicio clave no responde (503, timeout, etc.).
- Facilita la automatización de health checks post-despliegue sin necesidad de herramientas externas.

Además, aporta visibilidad del estado real de la aplicación al finalizar el CI/CD, integrando:
- Verificación HTTP de múltiples endpoints.
- Alerta automática por correo en caso de falla.

🔐 **Seguridad y buenas prácticas**

- La función está empaquetada en ZIP incluyendo la librería requests como dependencia externa.
- Utiliza verify=False para ignorar certificados autofirmados durante el testeo, evitando falsos negativos en ambientes no productivos.
- Responde con un JSON estructurado con los resultados individuales por URL.
- La salida de la Lambda es procesada automáticamente en el pipeline.

Si alguna URL no responde con 200 OK, el workflow:
- Se marca como fallido (exit 1)
- Envía un correo a un destinatario configurable con detalles del error

 ## ✉ Notificación
   - Se envía un correo a `$REPO_OWNER_MAIL` con resultados del pipeline y link al despliegue

 ![Notifs](/IMG/Notifs.png)


---

## ⌚ Cloudwatch
 Para el monitoreo y observabilidad se utilizó CloudWatch, un servicio propio de AWS. El mismo está constituido por dos partes principales: el dashboard y las alarmas.

 El **dashboard** es creado en terraform en la parte de despliegue de infraestructura. El mismo mantiene un registro de métricas de la utilización de CPU de las instancias del worker node del cluster que se usan para correr los contenedores de la aplicación. Se crea una dashboard para cada ambiente.

 ![Dashboard](/IMG/Dashboard.png)


 Por otro lado, si bien se intentó incluir las alarmas en el archivo de terraform también, no logramos hacerlas funcionar, por lo que se crearon manualmente de la siguente manera:
 - Se ingresa a la pestaña de CloudWatch y se selecciona "All Alarms" del menú de la izquierda.
 - Se hace click en "Create Alarm".
 - Se selecciona una métrica de la sección EKS para la cual deseamos crear una alarma (en nuestro caso, solicitudes HTTP que resultaron en código 5XX -error de servidor- y cantidad de intentos fallados del scheduler para desplegar los pods por error interno).
 - Se configuran los detalles de nombre, cluster, tipo de estadística y el período (en nuestro caso, todo por defecto).
 - Se establecen las condiciones para la alarma (en nuestro caso, "static" y "greater than 5").
 - Se selecciona "In alarm" y "Create new topic" para la recepción de notificación de alarma. Se agrega correo electrónico que recibirá la notificación.
 - Se agrega nombre de alarma (en nuestro caso "5XX_alarm" y "PodsFailed_alarm") y una descripción, si se desea.
 - Se confirma la creación de la alarma.

![Alarm](/IMG/Alarm.png)


---

## 🚧 CodeQL y  super-linter como *Quality Gate* en el Proceso de Integración Continua

Este repositorio utiliza [`codeql-analysis.yml`](.github/workflows/codeql-analysis.yml) para configurar y ejecutar [CodeQL](https://codeql.github.com/), una herramienta de análisis de código estático desarrollada por GitHub, para los siguientes lenguajes 'csharp', 'javascript', 'python'. En este caso, se aplica específicamente a la aplicación `voting-app`, con el objetivo de detectar automáticamente vulnerabilidades, errores y problemas de calidad en el código de sus distintos servicios.
En este repositorio, CodeQL se utiliza como un **_quality gate_ automático** durante el proceso de integración continua. Esto garantiza que el código que se fusiona en las ramas principales (`dev`, `test` y `main`) haya pasado un análisis de seguridad y calidad.

### 🔁 Flujo de trabajo

1. **Creación de un Pull Request hacia `dev`, `test` o `main`**
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
- 📐 **Consistencia**: Se aplica el mismo estándar en todos los entornos (`dev`, `test`, `main`).
- 🧹 **Reducción de deuda técnica**: Se previene la acumulación de errores y malas prácticas en el tiempo.
- 🚀 **Despliegues más confiables**: Cada rama mantiene un estado seguro y controlado.

---

📌 *EXTRA* Este proceso se complementa con la configuración de **branch protection rules** en GitHub, exigiendo que el análisis CodeQL se complete correctamente antes de permitir merges en las ramas protegidas.

---
Las configuraciones de las **branch protection rules** son las siguientes:

![QG_1.png](/IMG/QG_1.png)

![QG_2.png](/IMG/QG_2.png)

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

## 📸 Tablero Kanban

### Primera etapa:

![IMG/Trello 1.png](IMG/Trello%201.png)

### Segunda etapa:

![IMG/Trello 2.png](IMG/Trello%202.png)

### Tercera etapa:

![IMG/Trello 3.png](IMG/Trello%203.png)


---

### 📏 Decisiones de Diseño

- Como se mencionó anteriormente en la documentación, se incluyó tanto la infraestructura, como el código de la aplicación en el mismo repositorio ya que, en nuestro parecer, es un proyecto pequeño que se benefició de solamente tener un lugar de trabajo. Dado que fue nuestro primer intento de despliegue automatizado de infraestructura utilizando IaC, nos resultó útil tener ambas áreas juntas y en constante testeo.

- Se utilizó un solo workflow para todos los ambientes. Se parametrizó el ambiente del cual provino el push, lo que brinda mayor flexibilidad si se desean incluir más branches en el repositorio, ya que no será necesario crear workflows dedicados para las nuevas ramas, simplemente se deben contemplan sus nombres en el condicional inicial del workflow único.

- En AWS se utilizó una sola VPC con 6 subnets públicas (2 por cada ambiente: dev, test y main) y 3 clusters EKS (también uno por ambiente). Algunas de las razones que nos llevaron a tomar estas deciciones fueron: 
    - Menor "Blast Radius": si hay un error humano, una configuración errónea o un incidente de seguridad en un ambiente, el impacto se limita a ese clúster específico. Es mucho más difícil afectar accidentalmente el ambiente de producción desde desarrollo. 
    - Ciclo de vida y pruebas independientes: se pueden probar las actualizaciones de versión de Kubernetes en un clúster de desarrollo/QA antes de aplicarlas a producción. En un solo clúster, actualizar la versión del Kubernetes afectaría a todos los ambientes simultáneamente. 
    - Configuraciones de infraestructura específicas: cada clúster puede tener configuraciones de red, almacenamiento, balanceadores de carga o tipos de instancias subyacentes optimizadas para las necesidades específicas de ese ambiente (ej: menor costo en dev, alta disponibilidad y performance en main). Si bien en el obligatorio se utilizaron las mismas propiedades en todos los ambientes, se tuvo este punto en cuenta.
    - Especificaciones de EKS: Se utilizaron 2 subnets públicas ya que fue el menor número de subnets permitidas por EKS para la creación de clusters.

- Para la conexión de los clusters a internet, simplemente se cambió el "spec: type" de NodePort a LoadBalancer en los manifiestos de Service de Vote y Result. Eso generó que AWS cree automáticamente los ALBs necesarios para permitir el tráfico hacia la aplicación. Si bien fue algo simple de modificar, esto nos generó problemas a la hora de buscar los URLs de los ALBs utilizados, ya que no aparecían en la parte de "Ingresses" o "IngressClasses" en la sección "Resources" de los clusters.

- Para la IaC no se utilizaron módulos, pero se utilizó el mismo contenido del main.tf con variables diferenciadas por ambiente, lo que facilitó la realización de cambios y nos otorgó flexibilidad.

- No se utilizó la estrategia de Feature Branch para el desarrollo de la infraestructura dado que se creó en el mismo repositorio que la aplicación y no nos resultó práctico utilizar esta estrategia durante el transcurso del proyeto.

- El testing de carga se aplicó como Quality Gate, es decir, si el mismo falla, se cancela el resto del pipeline. El failure criteria se estableció en menos de "100% success", o sea, mientras nada falle, seguirá el pipeline.

- Si los pipelines de "super-linter.yml" o "codeql-analysis.yml" no llegan a completarse, esto no contituye un error, ya que se continúa con el despliegue de la infraestructura. En el caso de "codeql-analysis", éste termina de forma correcta, mientras que para "super-linter", es posible que no se complete dado que es una revision de HTML, CSS y otros archivos de código, que no nos corresponde arreglar en el presente obligatorio.


---

### 🎀 Lecciones aprendidas

- Al principio luchamos mucho con la lógica y la creación de la Infraestructura como Código, ya que estábamos tratando de crear subnets privadas y públicas conectadas a través de NAT gateways para mantener la seguridad de los clusters. Nos dimos cuenta que a veces menos es más, por lo menos en el caso del obligatorio. Nos gustaría poder modificarlo luego con una infraestructura similar a la mencionada.

- A pesar de que menos es más, en el caso de la búsqueda de los ALBs en el pipeline de CI/CD, nos dimos cuenta también que nada es imposible. Cuando comenzamos a desarrollar el pipeline, los ALBs creados automáticamente por los manifiestos kubernetes se ingresaban manualmente como secretos del repositorio, lo que significaba que el mismo se iba a romper cuando llegara a la parte del testing por primera vez. Una vez roto, se ingresarían los ALBs creados en el step anterior (despliegue de K8s) y luego se correría nuevamente el pipeline. Insatisfechos con esto, buscamos una solución utilizando el AWS API (query "LoadBalancerDescriptions[*].[LoadBalancerName,DNSName]"). Esto no fue suficiente, ya que, si bien traía los ALBs creados, no los podía filtrar por fecha de creación por ser ALBs clásicos (la API no soporta esta condición para este tipo de Load Balancer), cosa que necesitábamos para poder diferenciar los ALBs de los diferentes ambientes. Luego de mucho trabajo, llegamos a la línea "readarray -t dns_array_8080 < <( aws elb describe-load-balancers --output json | jq -r '.LoadBalancerDescriptions[] | select(.ListenerDescriptions[].Listener.LoadBalancerPort == 8080) | "\(.CreatedTime) \(.DNSName)"' | sort | awk '{print $2}')", que fue indispensable para la automatización del resto del pipeline. Básicamente, creamos un array con todos los ALBs (en este caso filtrados por puerto 8080, pero se realizó lo mismo para el puerto 8081), los cuales están ordenados por fecha de creación. Luego se crearon condicionales para determinar qué ALBs se tomarían basado en la posición en la que se encontraba (dado que nuestro repositorio sigue el orden de PR dev -> test -> main, sabíamos que el más antiguo sería el de dev y el más nuevo, de main). La posición 0 será de los ALBs de dev, la 1 de test y la 2 de main.
