FROM public.ecr.aws/lambda/python:3.11

# Instalar utilidades necesarias
RUN yum install -y unzip curl jq gettext bash git tar gzip less shadow-utils && \
    yum clean all

# Instalar kubectl
ENV KUBECTL_VERSION=1.31.2
RUN curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && mv kubectl /usr/local/bin/

# Instalar AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install

ENV PATH="/usr/local/aws-cli/v2/current/bin:${PATH}"

# Copiar función lambda
COPY lambda_function.py ${LAMBDA_TASK_ROOT}

# Instalar boto3 (aunque Lambda lo incluye por defecto)
RUN pip install boto3

# Establecer el handler
CMD ["lambda_function.lambda_handler"]
