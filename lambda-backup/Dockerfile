FROM amazonlinux:2

# Install dependencies
RUN yum install -y unzip curl jq gettext bash git

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

# Install kubectl
RUN curl -o kubectl https://amazon-eks.s3.us-east-1.amazonaws.com/1.31.2/2024-04-19/bin/linux/amd64/kubectl && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Copy the backup script
COPY backup.sh /backup.sh
RUN chmod +x /backup.sh

# Set the entrypoint to the backup script
ENTRYPOINT ["/backup.sh"]

