FROM google/cloud-sdk:slim

RUN apt-get update && apt-get install -y jq kubectl mongodb-clients && pip install python-dotenv pyyaml \
    && curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh \
    && chmod 700 get_helm.sh && ./get_helm.sh && rm ./get_helm.sh

RUN echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/3.6 main" | tee /etc/apt/sources.list.d/mongodb-org-3.6.list &&\
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5 &&\
    apt-get update && apt-get install -y mongodb-org-tools mongodb-org-shell

RUN echo '[ -f /k8s-ops/secret.json ] && gcloud auth activate-service-account --key-file=/k8s-ops/secret.json' >> ~/.bashrc
RUN echo '[ "${OPS_REPO_SLUG}" != "" ] && ! [ -d /ops ] && git clone --depth 1 --branch ${OPS_REPO_BRANCH:-master} https://github.com/${OPS_REPO_SLUG}.git /ops' >> ~/.bashrc
RUN echo '[ -d /ops ] && cd /ops' >> ~/.bashrc

WORKDIR /root

ENTRYPOINT ["bash"]
