FROM summerwind/actions-runner
USER root
# Override at build time with --build-arg to align this image with the
# kubernetes_version / helm_version pinned in the infrastructure repo's
# group_vars/all.yml.
ARG KUBECTL_VERSION=v1.36.0
ARG HELM_VERSION=v3.21.3
ARG YQ_VERSION=v4.53.6
ARG STERN_VERSION=v1.34.0
RUN apt-get update && apt-get upgrade -y && apt-get install -y curl unzip gnupg
RUN curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
 && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
RUN curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" -o /tmp/helm.tar.gz \
 && tar -xzf /tmp/helm.tar.gz -C /tmp \
 && install -o root -g root -m 0755 /tmp/linux-amd64/helm /usr/local/bin/helm \
 && rm -rf /tmp/helm.tar.gz /tmp/linux-amd64
RUN curl -L -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 \
    && chmod +x /usr/local/bin/yq
RUN curl -L https://github.com/stern/stern/releases/download/${STERN_VERSION}/stern_${STERN_VERSION}_linux_amd64.tar.gz | tar xz \
    && mv stern /usr/local/bin/

USER runner
