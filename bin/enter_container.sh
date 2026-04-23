#!/bin/bash
# enter_container.sh -- unified entry for sandbox or sif
# Usage:
#   ./enter_container.sh --sandbox
#   ./enter_container.sh --sif
#   ./enter_container.sh --sif --cleanenv
#   ./enter_container.sh --help

set -euo pipefail

ROOT="/data2/users/shihongfu/octopus"
SBOX="$ROOT/sandboxes/octopus-sandbox"
SIF="$ROOT/container/Octopus.sif"
BIND_DATA_HOST="$ROOT/data/CCVR5"
BIND_CONFIG_HOST="$ROOT/config"
BIND_RESULTS_HOST="$ROOT/results/CCVR5"

BIND_DATA="/mnt/data/CCVR5:ro"
BIND_CONFIG="/mnt/config:ro"
BIND_RESULTS="/mnt/results/CCVR5:rw"

CLEANENV="--cleanenv"
USE_CLEANENV=true

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--sandbox|--sif] [--no-cleanenv] [--help]
  --sandbox     Enter writable sandbox (singularity shell --writable)
  --sif         Enter built SIF (singularity shell)
  --no-cleanenv Do not use --cleanenv when entering SIF (inherit host env)
  --help        Show this help
USAGE
  exit 1
}

if [ $# -eq 0 ]; then
  usage
fi

MODE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --sandbox) MODE="sandbox"; shift ;;
    --sif) MODE="sif"; shift ;;
    --no-cleanenv) USE_CLEANENV=false; shift ;;
    --help) usage ;;
    *) echo "Unknown arg: $1"; usage ;;
  esac
done

# Ensure bind sources exist
if [ ! -d "$BIND_DATA_HOST" ]; then
  echo "ERROR: data path not found: $BIND_DATA_HOST" >&2
  exit 2
fi
if [ ! -d "$BIND_CONFIG_HOST" ]; then
  echo "ERROR: config path not found: $BIND_CONFIG_HOST" >&2
  exit 2
fi
mkdir -p "$BIND_RESULTS_HOST"
if [ ! -w "$BIND_RESULTS_HOST" ]; then
  echo "WARNING: results dir not writable: $BIND_RESULTS_HOST" >&2
fi

case "$MODE" in
  sandbox)
    if [ ! -e "$SBOX" ]; then
      echo "ERROR: sandbox not found: $SBOX" >&2
      exit 2
    fi
    singularity shell --writable \
      --bind "$BIND_DATA_HOST:$BIND_DATA" \
      --bind "$BIND_CONFIG_HOST:$BIND_CONFIG" \
      --bind "$BIND_RESULTS_HOST:$BIND_RESULTS" \
      "$SBOX"
    ;;
  sif)
    if [ ! -f "$SIF" ]; then
      echo "ERROR: SIF not found: $SIF" >&2
      exit 2
    fi
    CLEANOPT=""
    if [ "$USE_CLEANENV" = true ]; then
      CLEANOPT="--cleanenv"
    fi
    singularity shell $CLEANOPT \
      --bind "$BIND_DATA_HOST:$BIND_DATA" \
      --bind "$BIND_CONFIG_HOST:$BIND_CONFIG" \
      --bind "$BIND_RESULTS_HOST:$BIND_RESULTS" \
      "$SIF"
    ;;
  *)
    usage
    ;;
esac

