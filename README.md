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
