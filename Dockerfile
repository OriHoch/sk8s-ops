FROM google/cloud-sdk:alpine

RUN apk --update --no-cache add bash jq py2-pip openssl curl git \
    && pip install --upgrade pip \
    && pip install python-dotenv pyyaml \
    && gcloud --quiet components install kubectl \
    && curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh && chmod 700 get_helm.sh && ./get_helm.sh && rm ./get_helm.sh \
    && mkdir /ops

RUN echo '[ -f /k8s-ops/secret.json ] && gcloud auth activate-service-account --key-file=/k8s-ops/secret.json' >> ~/.bashrc
RUN echo '! [ -d /ops/environments ] && cd / && rm -rf /ops && git clone --depth 1 --branch ${OPS_REPO_BRANCH:-master} https://github.com/${OPS_REPO_SLUG:-OriHoch/sk8s}.git /ops' >> ~/.bashrc
RUN echo 'cd /ops' >> ~/.bashrc

WORKDIR /ops

ENTRYPOINT ["bash"]
