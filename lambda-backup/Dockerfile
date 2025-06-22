# Fase de construcción
FROM amazonlinux:2 AS builder

RUN yum install -y unzip curl jq gettext bash git tar gzip less shadow-utils && yum clean all

ENV KUBECTL_VERSION=1.31.2

# Instalar kubectl
RUN curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && mv kubectl /usr/local/bin/

# Instalar AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install && \
    rm -rf awscliv2.zip aws

# Copiar script
COPY backup.sh /backup.sh

# Imagen final basada en Lambda con Python (resuelve problema de libpython)
FROM public.ecr.aws/lambda/python:3.10

# Copiar binarios y scripts necesarios
COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=builder /usr/local/aws-cli /usr/local/aws-cli


# Asegurar PATH
ENV PATH="/usr/local/aws-cli/v2/current/bin:${PATH}"
COPY --from=builder /backup.sh /var/task/bootstrap

# Dar permisos de ejecución
RUN chmod +x /var/task/bootstrap

# Lambda custom runtime entrypoint
ENTRYPOINT ["/var/task/bootstrap"]




