# -------- STAGE 1: builder --------
FROM amazonlinux:2 AS builder

SHELL ["/bin/bash", "-c"]

# Instalar dependencias comunes
RUN yum update -y && \
    yum install -y unzip curl tar gzip bash less shadow-utils && \
    yum clean all

# Instalar kubectl versión fija
ENV KUBECTL_VERSION=v1.30.1
RUN curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && mv kubectl /usr/local/bin/kubectl

# -------- STAGE 2: Lambda runtime --------
FROM public.ecr.aws/lambda/provided:al2

SHELL ["/bin/bash", "-c"]

# Instalar dependencias para bash, curl, unzip
RUN yum update -y && \
    yum install -y bash curl unzip tar gzip less shadow-utils && \
    yum clean all

# Instalar AWS CLI v2 directamente en esta imagen
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# Copiar kubectl desde el builder
COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl

# Copiar el script
COPY lambda-entrypoint.sh /var/task/bootstrap
RUN chmod +x /var/task/bootstrap

#CMD ["/var/task/lambda-entrypoint.sh"]

