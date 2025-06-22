# Stage 1: Build utilities and tools
FROM amazonlinux:2 AS builder

# Install basic dependencies
RUN yum install -y unzip curl jq gettext bash git tar gzip less shadow-utils libxcrypt-compat && \
    yum clean all

# Install kubectl
ENV KUBECTL_VERSION=1.31.2
RUN curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && mv kubectl /usr/local/bin/

# Install static AWS CLI v2 binary
RUN curl -Lo "awscliv2.zip" "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" && \
    unzip -q awscliv2.zip && \
    ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli && \
    rm -rf aws awscliv2.zip

# Copy your backup script
COPY backup.sh /backup.sh


# Stage 2: Final runtime image (Lambda)
FROM public.ecr.aws/lambda/provided:al2

# Copy necessary tools from the builder stage
COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=builder /usr/local/bin/aws /usr/local/bin/aws
COPY --from=builder /bin/bash /bin/bash
COPY --from=builder /usr/bin/curl /usr/bin/curl
COPY --from=builder /usr/bin/unzip /usr/bin/unzip
COPY --from=builder /usr/bin/gettext /usr/bin/gettext

# Set PATH so AWS CLI can be found
ENV PATH="/usr/local/bin:$PATH"

# Copy the bootstrap script to Lambda's expected entry point
COPY --from=builder /backup.sh /var/task/bootstrap
RUN chmod +x /var/task/bootstrap

# Lambda expects a bootstrap entrypoint
ENTRYPOINT ["/var/task/bootstrap"]