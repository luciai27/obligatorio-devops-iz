# Fase de construcción
FROM amazonlinux:2 AS builder

# Instalar dependencias
RUN yum install -y unzip curl jq gettext bash git tar gzip less shadow-utils && \
    yum clean all

# Instalar kubectl
ENV KUBECTL_VERSION=1.31.2
RUN curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && mv kubectl /usr/local/bin/

# Instalar AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install

# Imagen final basada en Lambda Python
FROM public.ecr.aws/lambda/python:3.10


# Install AWS Lambda runtime interface client (REQUIRED) - Lo nuevo que agregué yo
RUN pip install --no-cache-dir awslambdaric

# Copiar binarios desde builder
COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=builder /usr/local/bin/aws /usr/local/bin/aws
COPY --from=builder /usr/local/aws-cli /usr/local/aws-cli

# Asegurar permisos y PATH
RUN chmod +x /usr/local/bin/aws /usr/local/bin/kubectl
ENV PATH="/usr/local/aws-cli/v2/current/bin:/usr/local/bin:${PATH}"

# Copiar código Python
COPY lambda_function.py .

# Handler para Lambda
CMD ["lambda_function.lambda_handler"]
