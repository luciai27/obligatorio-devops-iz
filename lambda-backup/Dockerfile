FROM public.ecr.aws/lambda/provided:al2.2025.06.19.11



RUN yum install -y unzip curl jq gettext bash git

# Instalar AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

# Instalar kubectl versión fija
ENV KUBECTL_VERSION=1.31.2
RUN curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/


# Copiar tu script
COPY backup.sh /backup.sh
RUN chmod +x /backup.sh

# Definir el handler
ENTRYPOINT ["/backup.sh"]

