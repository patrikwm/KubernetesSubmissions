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

# Define applications to build
# Format: "image_name:build_context:dockerfile_path"
APPS=(
  "todo-app:./todo-app:"
  "pingpong:./ping-pong_application:"
  "log-reader:./log_output:./log_output/Dockerfile.read"
  "log-writer:./log_output:./log_output/Dockerfile.write"
  "todo-backend:./todo-backend:"
)

# Build and push each application
for app_config in "${APPS[@]}"; do
  IFS=':' read -r image_name build_context dockerfile <<< "$app_config"

  echo "=> Building $image_name"

  # Build docker command
  build_cmd="docker build $build_context -t $REPO/$image_name:$TAG"

  # Add dockerfile if specified
  if [ -n "$dockerfile" ]; then
    build_cmd="$build_cmd -f $dockerfile"
  fi

  # Add push and quiet flags
  build_cmd="$build_cmd --push -q"

  # Execute build and capture digest
  DIGEST=$(eval "$build_cmd" | grep "sha256:" || echo "")

  if [ -n "$DIGEST" ]; then
    DIGESTS+=("$image_name: docker.io/$REPO/$image_name:$TAG@$DIGEST")
  fi
done


echo ""
echo "=== IMAGE DIGESTS ==="
for digest in "${DIGESTS[@]}"; do
  echo "$digest"
done