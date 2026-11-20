# RocketRide engine on Railway: the upstream server image, pinned by digest, with a start script that
# hands the Railway volume to the engine's user, refuses to run without an API key, and keeps odd
# deploy-form values from stopping the service (STANDARD 8.29).
ARG ROCKETRIDE_IMAGE=ghcr.io/rocketride-org/rocketride-engine:3.6.0@sha256:ccb906861322f967a5c896940f2ef6bdc80898fee9ac866c473d921e1eb9b6cc
FROM ${ROCKETRIDE_IMAGE}
USER root
# CPU builds of PyTorch for the nodes that run local models (embeddings, OCR, NER...). Upstream pins the
# CUDA 12.8 build, several GB of NVIDIA libraries that Railway (no GPUs) can't use and that fill the disk.
# The engine's own override mechanism (depends.py: ai/**/overrides.txt, ai/**/requirement*.txt) swaps them.
RUN mkdir -p /opt/rocketride/ai/railway \
 && printf '%s\n' '# Railway: CPU PyTorch wheels' '--extra-index-url https://download.pytorch.org/whl/cpu' \
      > /opt/rocketride/ai/railway/requirements.txt \
 && printf '%s\n' '# Railway: no GPUs, so the CPU builds of the pinned versions' \
      'torch==2.10.0+cpu' 'torchvision==0.25.0+cpu' > /opt/rocketride/ai/railway/overrides.txt
COPY --chmod=0755 railway-start.sh /usr/local/bin/railway-start.sh
ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
