FROM ubuntu:bionic

RUN apt update
RUN apt install -y software-properties-common
RUN apt-add-repository --yes --update ppa:ansible/ansible
RUN apt install -y ca-certificates curl procps sudo unzip wget python-pip python-dev ansible openssh-client jq iputils-ping netcat-openbsd
RUN wget -nc -P /tmp/bitnami/pkg/cache/ https://downloads.bitnami.com/files/stacksmith/kubectl-1.18.1-0-linux-amd64-debian-10.tar.gz && \
    echo "06a2e9f5af5fa3c2619661b096fe62d4bbb566995259653c1303d9bbfb034406  /tmp/bitnami/pkg/cache/kubectl-1.18.1-0-linux-amd64-debian-10.tar.gz" | sha256sum -c - && \
    tar -zxf /tmp/bitnami/pkg/cache/kubectl-1.18.1-0-linux-amd64-debian-10.tar.gz -P --transform 's|^[^/]*/files|/opt/bitnami|' --wildcards '*/files' && \
    rm -rf /tmp/bitnami/pkg/cache/kubectl-1.18.1-0-linux-amd64-debian-10.tar.gz
RUN apt-get update && apt-get upgrade -y && \
    rm -r /var/lib/apt/lists /var/cache/apt/archives

RUN chmod +x /opt/bitnami/kubectl/bin/kubectl
ENV PATH="/opt/bitnami/kubectl/bin:$PATH"

WORKDIR /app
COPY . /app
RUN pip install -r requirements.txt
RUN chmod +x addnode.sh deletenode.sh proxmoxlist.sh app.py

ENTRYPOINT [ "/bin/bash", "init.sh" ]

CMD [ "app.py" ]
