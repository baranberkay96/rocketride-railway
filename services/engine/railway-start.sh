#!/bin/sh
# Start the RocketRide engine on Railway (runs as root only long enough to prepare the volume).
set -u
log() { echo "railway-start: $*" >&2; }
random_key() { echo "rr_$(head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n')"; }

# Task data (/opt/data) is the Railway volume; a fresh one belongs to root, the engine runs as uid 1000.
data=/opt/data
mkdir -p "$data"
[ "$(stat -c %u "$data")" = 1000 ] || chown 1000:1000 "$data"

# Without a key the engine accepts any non-empty one, so it must never start without a valid one here.
# MCP clients also need the rr_ prefix. A bad value locks the engine with a random key instead of
# failing the deploy.
key=${ROCKETRIDE_APIKEY:-}
if printf '%s' "$key" | grep -Eq '^rr_[A-Za-z0-9_-]{16,200}$'; then
  :
else
  log "ROCKETRIDE_APIKEY must be rr_ followed by 16-200 letters, digits, _ or -. The engine is locked with a random key"
  log "nobody knows until you set a valid one on this service and redeploy."
  key=$(random_key)
fi
export ROCKETRIDE_APIKEY="$key"

port=${PORT:-5565}
case "$port" in
  '' | *[!0-9]*) log "PORT '$port' is not a number; using 5565"; port=5565 ;;
esac
export PORT="$port"
# Engine image 3.6.0 and earlier send MCP tool calls to RocketRide Cloud unless this points at the engine.
export ROCKETRIDE_URI="${ROCKETRIDE_URI:-ws://127.0.0.1:${port}}"
# PyTorch's CPU index for the overrides in /opt/rocketride/ai/railway, also in the tasks' environment.
export UV_EXTRA_INDEX_URL="${UV_EXTRA_INDEX_URL:-https://download.pytorch.org/whl/cpu}"
export UV_LINK_MODE="${UV_LINK_MODE:-copy}"
export RR_SUBPROCESS_ENV="${RR_SUBPROCESS_ENV:-UV_*}"

cd /opt/rocketride
exec setpriv --reuid=1000 --regid=1000 --init-groups --inh-caps=-all \
  env HOME=/home/rocketride USER=rocketride \
  ./engine ./ai/eaas.py --host=0.0.0.0 --port="$port" "$@"
