# Ops

Interact with Kubernetes / Google Cloud environments from CI / automation scripts. Integrates with [sk8s](https://github.com/OriHoch/sk8s)

Available on docker hub in the following variants:

* `orihoch/sk8s-ops` - contains `gcloud`, `kubectl`, `gsutil`, `helm`
* `orihoch/sk8s-ops:mongo` - with mongo related CLI tools
* `orihoch/sk8s-ops:mysql` - with mysql related CLI tools

The following images based on this image may also be useful:
* `orihoch/sk8sops:pipelines-google-storage-sync` - sync of data to / from google storage, see [sk8s-pipelines/google-storage-sync/README.md](https://github.com/OriHoch/sk8s-pipelines/blob/master/google-storage-sync/README.md)

## Running the ops image directly

Start a bash terminal

```
docker run -it orihoch/sk8sops
```


## Authenticating with gcloud

You need a service account json key, see below on how to create one

Assuming you have the key file at `secret-k8s-ops.json`:

```
docker run -v "`readlink -f ./secret-k8s-ops.json`:/k8s-ops/secret.json" \
           -it orihoch/sk8sops
```


## Cloning an ops repo

The image can clone an ops repo containing your project's helm / configuration files / scripts

```
docker run -v "`readlink -f ./secret-k8s-ops.json`:/k8s-ops/secret.json" \
           -e "OPS_REPO_SLUG=OriHoch/sk8s" \
           -it orihoch/sk8sops
```

You can specify `OPS_REPO_BRANCH` as well, it defaults to `master`


## Using the run_docker_ops.sh script

You can use the `run_docker_ops.sh` script to more tightly integrate with [sk8s](https://github.com/OriHoch/sk8s) compatible repos and to support running from CI tools.

There are 2 requirements to running the script:

* a Google Cloud service account key which should be available at current working directory under `secret-k8s-ops.json`. See below on how to create it.
* a sk8s repository at a GitHub public repo (for example https://github.com/Midburn/midburn-k8s`)

```
./run_docker_ops.sh "<ENVIRONMENT_NAME>" "" "orihoch/sk8sops" "<SK8S_REPO_SLUG>"
```

You can run the script from external repositories / tools by downloading it and running directly

```
wget https://raw.githubusercontent.com/OriHoch/sk8s/master/run_docker_ops.sh && chmod +x run_docker_ops.sh
./run_docker_ops.sh "staging" "kubectl get pods" "orihoch/sk8sops" <SK8S_REPO_SLUG>
```

Check the script parameters and code for more run options


## Secrets

Assuming you have the key file at `secret-k8s-ops.json`:

```
! kubectl describe secret ops &&\
  kubectl create secret generic ops "--from-file=secret.json=secret-k8s-ops.json"
```

Set in values

```
ops:
  secret: ops
```

Use in pod specs

```
containers:
- name: ops
  image: orihoch/sk8sops
  resources:
    requests:
      cpu: "0.001"
      memory: "10Mi"
  command:
  - bash
  - "-c"
  - "while true; do sleep 86400; done"
  volumeMounts:
  - name: k8s-ops
    mountPath: /k8s-ops
    readOnly: true
volumes:
- name: k8s-ops
  secret:
    secretName: ops
```


## Build and publish the docker ops image

If you don't require additional dependencies you can use `orihoch/sk8s-ops` image on public docker hub, in this case skip to set in values below.

Otherwise, you should build the ops image and publish yourself.

The ops image only contains the system dependencies, the code and configurations are pulled directory from Git - so you shouldn't need to update it often.

You can use google container builder service to build the image

```
gcloud --project=${CLOUDSDK_CORE_PROJECT} container builds submit --tag gcr.io/${CLOUDSDK_CORE_PROJECT}/sk8s .
```

pull, tag and push to public docker hub

```
gcloud docker -- pull gcr.io/${CLOUDSDK_CORE_PROJECT}/sk8s
docker tag gcr.io/${CLOUDSDK_CORE_PROJECT}/sk8s orihoch/sk8s
docker push orihoch/sk8s
```

Set in values

```
ops:
  image: orihoch/sk8s@sha256:5660a773e64b6ec495f4f5f62211bd85ceb3452e9372f8a7a270c112804b03f3
```


## Creating a new service account with full permissions and related key file

This will create a key file at `secret-k8s-ops.json` - it should not be committed to Git.

```
export SERVICE_ACCOUNT_NAME="k8s-ops"
export SERVICE_ACCOUNT_ID="${SERVICE_ACCOUNT_NAME}@${CLOUDSDK_CORE_PROJECT}.iam.gserviceaccount.com"

! gcloud iam service-accounts list | grep "${SERVICE_ACCOUNT_ID}" &&\
    gcloud iam service-accounts create "${SERVICE_ACCOUNT_NAME}"

! [ -f "secret-k8s-ops.json" ] &&\
    gcloud iam service-accounts keys create "--iam-account=${SERVICE_ACCOUNT_ID}" \
                                            "secret-k8s-ops.json"

gcloud projects add-iam-policy-binding --role "roles/storage.admin" "${CLOUDSDK_CORE_PROJECT}" \
                                       --member "serviceAccount:${SERVICE_ACCOUNT_ID}"
gcloud projects add-iam-policy-binding --role "roles/cloudbuild.builds.editor" "${CLOUDSDK_CORE_PROJECT}" \
                                       --member "serviceAccount:${SERVICE_ACCOUNT_ID}"
gcloud projects add-iam-policy-binding --role "roles/container.admin" "${CLOUDSDK_CORE_PROJECT}" \
                                       --member "serviceAccount:${SERVICE_ACCOUNT_ID}"
gcloud projects add-iam-policy-binding --role "roles/viewer" "${CLOUDSDK_CORE_PROJECT}" \
                                       --member "serviceAccount:${SERVICE_ACCOUNT_ID}"
```
