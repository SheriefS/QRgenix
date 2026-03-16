FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
      openssh-client \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
      ansible-core \
      kubernetes \
      PyYAML

RUN ansible-galaxy collection install \
      kubernetes.core \
      community.general

WORKDIR /ansible
ENTRYPOINT ["ansible-playbook"]
