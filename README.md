# Obligatorio Voting App

### Herramientas:
- Repositorio: GitHub
- CI/CD: GitHub Actions
- Análisis de código estático: SonarQube
- Cloud: AWS
- IaC: Terraform
- Testing: JMeter

### Estrategia Git Flow
La estrategia elegida fue Git Flow. Si bien entendemos que la estrategia Trunk based tiene características que podrían ser útiles en nuestra situación (promueve la integración continua, especialmente útil para proyecto pequeños), decidimos utilizar la estrategia Git Flow ya que nos permite observar más atentamente los cambios realizados a la rama principal. Dado que todavía estamos comprendiendo cómo utilizar las tecnologías enseñadas en clase, consideramos que un monitoreo más a fondo de lo que se incorpora es la estrategia que más se alinea con nuestra forma de trabajo. Al utilizar esta estrategia, sabemos que lo que se integra a la rama principal está funcionando correctamente.

### Prerequisitos
- AWS_ACCESS_KEY_ID
- AWS_REGION
- AWS_SECRET_ACCESS_KEY
- AWS_SESSION_TOKEN
- BUCKET_NAME (nombre para guardar las imagenes, un backet puede tener un nombre unico, )
- EMAIL_PASS
- EMAIL_USER
- REPO_OWNER_MAIL
- SONAR_TOKEN

### Estrategia de Repo Infra (una carpeta en el mismo repo)
Decidimos utilizar el mismo repositorio para la carpeta de infraestructura. Dado que nuestro proyecto es pequeño, consideramos que es más útil para nosotros incluir todo en el mismo repositorio, así podemos realizar cambios en archivos tanto de aplicación, como de infraestructura sin tener que cambiar de lugar de trabajo. Si bien entendemos que un repositorio único para infraestructura sería útil para proyectos grandes y para lograr reusar infraestructura, consideramos que no es necesario en nuestro caso.

## Arquitectura

![Architecture diagram](architecture.excalidraw.png)

* A front-end web app in [Python](/vote) which lets you vote between two options
* A [Redis](https://hub.docker.com/_/redis/) which collects new votes
* A [.NET](/worker/) worker which consumes votes and stores them in…
* A [Postgres](https://hub.docker.com/_/postgres/) database backed by a Docker volume
* A [Node.js](/result) web app which shows the results of the voting in real time


####
Flow de CI/CD