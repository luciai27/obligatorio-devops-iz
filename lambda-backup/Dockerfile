FROM public.ecr.aws/lambda/provided:al2.2025.06.19.11




# Instalar dependencias
RUN yum install -y curl jq gettext bash git tar gzip less



# Instalar AWS CLI v2 desde tar.gz
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.tar.gz" -o "awscliv2.tar.gz" && \
    tar -xzf awscliv2.tar.gz && \
    ./aws/install && \
    rm -rf aws awscliv2.tar.gz

# Instalar kubectl versión fija
ENV KUBECTL_VERSION=1.31.2
RUN curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/



# Copiar script
COPY backup.sh /backup.sh
RUN chmod +x /backup.sh

# Definir el handler
ENTRYPOINT ["/backup.sh"]

