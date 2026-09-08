# General information

> [!NOTE]
> This repository holds Kubernetes self-hosted runner configuration scripts and Dockerfile
> 
> On-Premise infrastructure managed by GitHub actions provision workflows will manage k8s runner setup.
>
> Kubernetes Self-hosted runner is used to handle all OpenCRVS workflows except Provision workflow

# How to manually deploy self-hosted runner on Kubernetes cluster?

Self-hosted k8s runner is compatible with any kubernetes cluster including minikube on Linux or Apple Silicon. Certificate manager is required as hard dependency and is included in installation script. 

Make sure you are connected to correct cluster:
```
kubectl config current-context
```

Example output:
```
vmudryi@public-k8s
```
Output format:
```
<username>@<cluster-name>
```


Install runner by running following command:
```
export GITHUB_PAT=<your PAT with access to repository code and workflows>
export GIT_REPOSITORY=<your repository>
./k8s-runner.sh
```

Check you repository configuration -> action runners

# Image build & rebuild strategy

The runner image (`ghcr.io/opencrvs/opencrvs-github-runner`) is built by
[`.github/workflows/build-and-push-runner-image.yml`](.github/workflows/build-and-push-runner-image.yml)
from the [`Dockerfile`](Dockerfile), which bakes in `kubectl` and `helm` at
versions controlled by the `KUBECTL_VERSION`/`HELM_VERSION` build args.

The workflow runs on:
- **Push** to any branch/tag in this repo (tags produce a matching image tag; other pushes produce a short-commit-hash tag).
- **Weekly schedule** (Mondays 03:00 UTC), so the base image and OS packages get refreshed even without a code change here.
- **Manual dispatch**, optionally overriding `kubectl_version`/`helm_version` for that build.
- **`repository_dispatch` (type `rebuild`)**, so another repository can trigger a rebuild with specific versions, e.g. from `opencrvs/infrastructure` whenever it bumps `kubernetes_version`/`helm_version` in `group_vars/all.yml`:
  ```
  gh api repos/opencrvs/github-opencrvs-self-hosted-runner/dispatches \
    -f event_type=rebuild \
    -F 'client_payload[kubectl_version]=v1.36.0' \
    -F 'client_payload[helm_version]=v3.21.3'
  ```

Every successful build also retags and pushes `:latest`.
