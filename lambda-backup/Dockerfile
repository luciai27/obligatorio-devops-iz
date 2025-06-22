
FROM amazonlinux:2 AS builder

# Instalar dependencias necesarias
RUN yum install -y unzip curl jq gettext bash git tar gzip less

# Instalar kubectl
ENV KUBECTL_VERSION=1.31.2
RUN curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && mv kubectl /usr/local/bin/

# Instalar AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install

# Copiar script
COPY backup.sh /backup.sh


# ----------------------
# Imagen final para Lambda
# ----------------------
FROM public.ecr.aws/lambda/provided:al2

# Copiar binarios desde la etapa builder
COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=builder /usr/local/bin/aws /usr/local/bin/aws
COPY --from=builder /usr/bin/unzip /usr/bin/unzip
COPY --from=builder /backup.sh /var/task/bootstrap

RUN chmod +x /var/task/bootstrap

# Lambda container ENTRYPOINT debe ser bootstrap
ENTRYPOINT ["/var/task/bootstrap"]


