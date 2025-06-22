# Fase de construcción
FROM amazonlinux:2 AS builder

# Instalar utilidades necesarias
RUN yum install -y unzip curl jq gettext bash git tar gzip less shadow-utils && \
    yum clean all

# Instalar kubectl
ENV KUBECTL_VERSION=1.31.2
RUN curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && mv kubectl /usr/local/bin/

# Instalar AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install

# Copiar script
COPY backup.sh /backup.sh


# Imagen final basada en Lambda AL2
FROM public.ecr.aws/lambda/provided:al2

# Copiar binarios y script
COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=builder /usr/local/bin/aws /usr/local/bin/aws
COPY --from=builder /usr/local/aws-cli /usr/local/aws-cli


# Setear PATH para que aws funcione
ENV PATH="/usr/local/aws-cli/v2/current/bin:${PATH}"

# Copiar script y establecer como bootstrap
COPY --from=builder /backup.sh /var/task/bootstrap
RUN chmod +x /var/task/bootstrap

# Lambda requiere este ENTRYPOINT
ENTRYPOINT ["/var/task/bootstrap"]



