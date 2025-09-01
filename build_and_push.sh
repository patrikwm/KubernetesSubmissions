#!/usr/bin/env bash
set -euo pipefail

# Usage: ./build_and_push.sh 1.12
# This will build and push all images with the tag :1.12

if [ $# -ne 1 ]; then
  echo "Usage: $0 <tag>"
  exit 1
fi

TAG=$1
REPO="pjmartin"

echo "Building and pushing images with tag: $TAG"

# Array to store image digests
declare -a DIGESTS=()

# --- todo_app ---
echo "=> Building todo_app"
DIGEST=$(docker build ./todo_app \
  -t $REPO/todo_app:$TAG \
  --push -q | grep "sha256:" || echo "")
if [ -n "$DIGEST" ]; then
  DIGESTS+=("todo_app: docker.io/$REPO/todo_app:$TAG@$DIGEST")
fi

# --- ping-pong_application ---
echo "=> Building pingpong"
DIGEST=$(docker build ./ping-pong_application \
  -t $REPO/pingpong:$TAG \
  --push -q | grep "sha256:" || echo "")
if [ -n "$DIGEST" ]; then
  DIGESTS+=("pingpong: docker.io/$REPO/pingpong:$TAG@$DIGEST")
fi

# --- log_output reader ---
echo "=> Building log-reader"
DIGEST=$(docker build ./log_output \
  -f ./log_output/Dockerfile.read \
  -t $REPO/log-reader:$TAG \
  --push -q | grep "sha256:" || echo "")
if [ -n "$DIGEST" ]; then
  DIGESTS+=("log-reader: docker.io/$REPO/log-reader:$TAG@$DIGEST")
fi

# --- log_output writer ---
echo "=> Building log-writer"
DIGEST=$(docker build ./log_output \
  -f ./log_output/Dockerfile.write \
  -t $REPO/log-writer:$TAG \
  --push -q | grep "sha256:" || echo "")
if [ -n "$DIGEST" ]; then
  DIGESTS+=("log-writer: docker.io/$REPO/log-writer:$TAG@$DIGEST")
fi


echo ""
echo "=== IMAGE DIGESTS ==="
for digest in "${DIGESTS[@]}"; do
  echo "$digest"
done