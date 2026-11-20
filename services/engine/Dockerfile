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
      'torch==2.10.0+cpu' 'torchvision==0.25.0+cpu' > /opt/rocketride/ai/railway/overrides.txt \
 && find /opt/rocketride/ai/railway -type f | while read -r f; do touch -d "@$(stat -c %Y "$f")" "$f"; done
# Resolve the engine's constraints with these files now (as upstream's node image does), so the engine
# doesn't recompile them against PyPI at every start. depends() keys them on file mtimes in whole
# seconds, hence the touch above. Best effort: without it the engine compiles them at its first start.
USER rocketride
RUN cd /opt/rocketride && (./engine -c "from depends import ensure_constraints; ensure_constraints()" \
      || echo "constraints not precompiled; the engine compiles them at start")
USER root
COPY --chmod=0755 railway-start.sh /usr/local/bin/railway-start.sh
ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
