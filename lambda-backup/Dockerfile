
FROM amazonlinux:2 AS builder

# Instalar dependencias
RUN yum install -y unzip curl jq gettext bash git tar gzip less


# Instalar kubectl
ENV KUBECTL_VERSION=1.31.2
RUN curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && mv kubectl /usr/local/bin/

# Instalar AWS CLI v2 como binario directo
RUN curl -o /usr/local/bin/aws "https://s3.amazonaws.com/aws-cli/awscli-bundle/aws" && \
    chmod +x /usr/local/bin/aws


# Copiar script
COPY backup.sh /backup.sh
# Etapa 2: Imagen final compatible con Lambda
FROM public.ecr.aws/lambda/provided:al2.2025.06.19.11

# Copiar binarios desde la etapa builder
COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=builder /usr/local/aws-cli /usr/local/aws-cli

# Configurar PATH para AWS CLI
ENV PATH="/usr/local/aws-cli/v2/current/bin:$PATH"

COPY backup.sh /backup.sh
RUN chmod +x /backup.sh

# Definir el handler
ENTRYPOINT ["/backup.sh"]

