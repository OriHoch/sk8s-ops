# Ops

## Using the run_docker_ops.sh script

This script allows to interact with a sk8s environment from CI / automation scripts

There are 2 requirements to running the script:

* a Google Cloud service account key which should be available at current working directory under `secret-k8s-ops.json`. See below on how to create it.
* a sk8s repository at a GitHub public repo (for example https://github.com/Midburn/midburn-k8s`)

Running locally

```
cd sk8s-ops
docker build -t sk8s-ops .
./run_docker_ops.sh "<ENVIRONMENT_NAME>" "" "sk8s-ops" "<SK8S_REPO_SLUG>"
```

You can run the script from external repositories / tools by downloading it and running directly

```
wget https://raw.githubusercontent.com/OriHoch/sk8s/master/run_docker_ops.sh && chmod +x run_docker_ops.sh
./run_docker_ops.sh "staging" "kubectl get pods" <OPS_DOCKER_IMAGE> <SK8S_REPO_SLUG>
```

Check the script parameters and code for more run options


## Secrets

Assuming you have the key file at `secret-k8s-ops.json`:

```
! kubectl describe secret ops &&\
  kubectl create secret generic ops "--from-file=secret.json=secret-k8s-ops.json.json"
```

Set in values

```
ops:
  secret: ops
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
