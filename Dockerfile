# Runner base image:
#   ghcr.io/actions/actions-runner - official image, used by gha-runner-scale-set (ephemeral runners)
#   summerwind/actions-runner      - legacy summerwind actions-runner-controller
ARG BASE_IMAGE=ghcr.io/actions/actions-runner
FROM ${BASE_IMAGE}
USER root
# Override at build time with --build-arg to align this image with the
# kubernetes_version / helm_version pinned in the infrastructure repo's
# group_vars/all.yml.
# The "renovate:" comments let Renovate update the defaults, see renovate.json.
# renovate: datasource=github-releases depName=kubernetes/kubernetes extractVersion=^v(?<version>.+)$
ARG KUBECTL_VERSION=1.36.0
# renovate: datasource=github-releases depName=helm/helm extractVersion=^v(?<version>.+)$
ARG HELM_VERSION=3.21.3
# renovate: datasource=github-releases depName=mikefarah/yq extractVersion=^v(?<version>.+)$
ARG YQ_VERSION=4.53.6
# renovate: datasource=github-releases depName=stern/stern extractVersion=^v(?<version>.+)$
ARG STERN_VERSION=1.34.0
RUN apt-get update && apt-get upgrade -y && apt-get install -y curl unzip gnupg
RUN curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
 && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
RUN curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" -o /tmp/helm.tar.gz \
 && tar -xzf /tmp/helm.tar.gz -C /tmp \
 && install -o root -g root -m 0755 /tmp/linux-amd64/helm /usr/local/bin/helm \
 && rm -rf /tmp/helm.tar.gz /tmp/linux-amd64
RUN curl -L -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 \
    && chmod +x /usr/local/bin/yq
RUN curl -fL "https://github.com/stern/stern/releases/download/v${STERN_VERSION}/stern_${STERN_VERSION#v}_linux_amd64.tar.gz" | tar xz \
    && mv stern /usr/local/bin/

USER runner
