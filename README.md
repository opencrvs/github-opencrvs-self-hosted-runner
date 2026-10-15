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

The runner images are built by
[`.github/workflows/build-and-push-runner-image.yml`](.github/workflows/build-and-push-runner-image.yml)
from the same [`Dockerfile`](Dockerfile), which bakes in `kubectl`, `helm`, `yq` and `stern` at
versions controlled by the `KUBECTL_VERSION`/`HELM_VERSION`/`YQ_VERSION`/`STERN_VERSION` build args.

The workflow builds a matrix of two images that differ only by the `BASE_IMAGE` build arg:

| Image (`repository`) | `BASE_IMAGE` | Used by |
|---|---|---|
| `ghcr.io/opencrvs/opencrvs-github-ephemeral-runner` | `ghcr.io/actions/actions-runner` | `gha-runner-scale-set` (ephemeral runners), `arc_mode: scale-set` in the infrastructure repo |
| `ghcr.io/opencrvs/opencrvs-github-runner` | `summerwind/actions-runner` | legacy `summerwind` actions-runner-controller, `arc_mode: legacy`. Deprecated, removed together with legacy runner support (after v2.4) |

To build one of them locally:
```
docker build --build-arg BASE_IMAGE=ghcr.io/actions/actions-runner -t opencrvs-github-ephemeral-runner .
```

The workflow runs on:
- **Push** to any branch/tag in this repo.
- **Weekly schedule** (Mondays 03:00 UTC), so the base image and OS packages get refreshed even without a code change here.
- **Manual dispatch**, building from any `branch_tag_name` (default `develop`), optionally overriding `kubectl_version`/`helm_version` for that build — mirrors the "Publish images from any branch or tag" pattern used in `opencrvs-core`'s [`build-images-from-branch.yml`](https://github.com/opencrvs/opencrvs-core/blob/develop/.github/workflows/build-images-from-branch.yml).
- **`repository_dispatch` (type `rebuild`)**, so another repository can trigger a rebuild with specific branch/versions, e.g. from `opencrvs/infrastructure` whenever it bumps `kubernetes_version`/`helm_version` in `group_vars/all.yml`:
  ```
  gh api repos/opencrvs/github-opencrvs-self-hosted-runner/dispatches \
    -f event_type=rebuild \
    -F 'client_payload[branch_tag_name]=develop' \
    -F 'client_payload[kubectl_version]=v1.36.0' \
    -F 'client_payload[helm_version]=v3.21.3'
  ```

Every build pushes two tags per image — the short commit SHA of the checked-out ref
(`version`) and the escaped branch/tag name (`branch`).

`:latest` is what the runners pull, so it is only pushed when the built ref is the
repository's default branch (`develop`): pushes to `develop`, the weekly schedule, and
dispatches that build `develop`. Builds from any other branch or tag are published under
their version and branch tags only, which is how to test a branch on a cluster without
affecting the runners that follow `latest`, e.g. `arc_scale_set_runner_version: <branch>`
in the infrastructure repo.
