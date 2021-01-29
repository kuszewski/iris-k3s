FROM ubuntu:20.04
USER root
RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y curl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl
USER 51773
COPY monitor.sh .
CMD ["bash", "monitor.sh"]
