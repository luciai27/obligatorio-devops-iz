# -------- STAGE 1: builder --------
FROM amazonlinux:2 AS builder

SHELL ["/bin/bash", "-c"]

# Instalar dependencias
RUN yum update -y && \
    yum install -y unzip curl tar gzip bash less shadow-utils && \
    yum clean all

# Instalar AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# Instalar kubectl versión fija
ENV KUBECTL_VERSION=v1.30.1
RUN curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && mv kubectl /usr/local/bin/kubectl

# -------- STAGE 2: Lambda runtime --------
FROM public.ecr.aws/lambda/provided:al2

# Instalar bash (ya que usamos #!/bin/bash en el script)
RUN yum install -y bash && yum clean all

# Copiar binarios desde builder
COPY --from=builder /usr/local/bin/aws /usr/local/bin/aws
COPY --from=builder /usr/local/aws-cli /usr/local/aws-cli
COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl

# Copiar script de entrada
COPY lambda-entrypoint.sh /var/task/lambda-entrypoint.sh
RUN chmod +x /var/task/lambda-entrypoint.sh

# Lambda entrypoint
CMD ["/var/task/lambda-entrypoint.sh"]
