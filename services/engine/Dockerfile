# RocketRide engine on Railway: the upstream server image, pinned by digest, with a start script that
# hands the Railway volume to the engine's user, refuses to run without an API key, and keeps odd
# deploy-form values from stopping the service (STANDARD 8.29).
ARG ROCKETRIDE_IMAGE=ghcr.io/rocketride-org/rocketride-engine:3.6.0@sha256:ccb906861322f967a5c896940f2ef6bdc80898fee9ac866c473d921e1eb9b6cc
FROM ${ROCKETRIDE_IMAGE}
USER root
COPY --chmod=0755 railway-start.sh /usr/local/bin/railway-start.sh
ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
