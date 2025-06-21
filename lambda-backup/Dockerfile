FROM amazonlinux:2

RUN yum install -y unzip curl jq gettext bash git \
    && curl -o kubectl https://amazon-eks.s3.us-east-1.amazonaws.com/1.31.2/2024-04-19/bin/linux/amd64/kubectl \
    && chmod +x kubectl && mv kubectl /usr/local/bin/

COPY backup.sh /backup.sh
RUN chmod +x /backup.sh

ENTRYPOINT ["/backup.sh"]

