FROM public.ecr.aws/lambda/provided.al2:2023.03.31.14


# Instalar dependencias
RUN yum install -y unzip curl tar gzip bash

# Instalar AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

# Instalar kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Copiar tu script
COPY backup.sh /backup.sh
RUN chmod +x /backup.sh

# Definir el handler
ENTRYPOINT ["/backup.sh"]

