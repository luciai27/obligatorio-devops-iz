#FROM amazonlinux:2 AS builder

# Instalar dependencias
#RUN yum install -y unzip curl jq gettext bash git tar gzip less shadow-utils libxcrypt-compat && \
#    yum clean all

# Instalar kubectl
#ENV KUBECTL_VERSION=1.31.2
#RUN curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
#    chmod +x kubectl && mv kubectl /usr/local/bin/

# Instalar AWS CLI v2
#RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
#    unzip awscliv2.zip && ./aws/install

#COPY backup.sh /backup.sh


# Imagen final (AL2 sin runtime Python)
#FROM public.ecr.aws/lambda/provided:al2

# Copiar CLI y utilidades
#COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl
#COPY --from=builder /usr/local/aws-cli /usr/local/aws-cli
#COPY --from=builder /bin/bash /bin/bash
#COPY --from=builder /usr/bin/curl /usr/bin/curl
#COPY --from=builder /usr/bin/unzip /usr/bin/unzip
#COPY --from=builder /usr/bin/gettext /usr/bin/gettext

# Setear PATH para AWS CLI funcione
#ENV PATH="/usr/local/aws-cli/v2/current/bin:$PATH"

# Copiar el script como bootstrap
#COPY --from=builder /backup.sh /var/task/bootstrap
#RUN chmod +x /var/task/bootstrap

# Lambda espera un entrypoint llamado bootstrap
#ENTRYPOINT ["/var/task/bootstrap"]

# Etapa base con Python para Lambda
#ROM public.ecr.aws/lambda/python:3.13

# Copiar el archivo de función Lambda
#OPY lambda_function.py ${LAMBDA_TASK_ROOT}

# Link /opt/hostedtoolcache as /actions-runner/_work/_tool
#RUN ln -s /opt/hostedtoolcache _work/_tool

# Instalar dependencias si las tuvieras (por ejemplo, boto3, requests, etc.)
# RUN pip install -r requirements.txt -t ${LAMBDA_TASK_ROOT}

# Establecer el handler de entrada (no cambiar si usás lambda_function.lambda_handler)
# CMD ["lambda_function.lambda_handler"]

#FROM public.ecr.aws/lambda/provided:al2

# Instalar bash, curl, unzip, awscli y kubectl
#RUN yum install -y unzip curl tar gzip bash less \
# && curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
# && chmod +x kubectl \
# && mv kubectl /usr/local/bin/ \
# && yum install -y awscli \
# && yum clean all

# Copiar el script
#COPY lambda-entrypoint.sh /var/task/lambda-entrypoint.sh
#RUN chmod +x /var/task/lambda-entrypoint.sh

# Definir el entrypoint del contenedor
#CMD ["/var/task/lambda-entrypoint.sh"]

# -------- STAGE 1: Build image with all tools --------
FROM amazonlinux:2 AS builder

RSHELL ["/bin/bash", "-c"]

# Actualizar e instalar herramientas necesarias
RUN yum update -y && \
    yum install -y unzip curl tar gzip bash less shadow-utils awscli && \
    yum clean all

# Descargar kubectl con versión fija o dinámica
ENV KUBECTL_VERSION=$(curl -s https://dl.k8s.io/release/stable.txt)
RUN curl -LO https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/kubectl

# ---------- STAGE 2 ----------
FROM public.ecr.aws/lambda/provided:al2

# Copiar binarios desde el builder
COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/
COPY --from=builder /usr/bin/aws /usr/bin/
COPY --from=builder /usr/lib/aws /usr/lib/aws
COPY --from=builder /usr/share/aws-cli /usr/share/aws-cli
COPY --from=builder /etc/alternatives/aws /etc/alternatives/aws

# Copiar el script
COPY lambda-entrypoint.sh /var/task/lambda-entrypoint.sh
RUN chmod +x /var/task/lambda-entrypoint.sh

# EntryPoint Lambda
CMD ["/var/task/lambda-entrypoint.sh"]