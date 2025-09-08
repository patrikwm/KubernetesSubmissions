#!/usr/bin/env bash
set -euo pipefail

# Usage: ./build_and_push.sh 1.12
# This will build and push all images with the tag :1.12 for both ARM64 and x86_64

if [ $# -ne 1 ]; then
  echo "Usage: $0 <tag>"
  exit 1
fi

TAG=$1
REPO="pjmartin"

echo "Building and pushing multi-architecture images with tag: $TAG"

# Create and use a new buildx builder instance for multi-arch builds
echo "Setting up Docker buildx for multi-architecture builds..."
docker buildx create --name multiarch-builder --use --bootstrap || docker buildx use multiarch-builder

# Array to store image digests
declare -a DIGESTS=()
declare -a ARM64_IMAGES=()
declare -a X86_64_IMAGES=()

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

  echo "=> Building multi-arch $image_name"

  # Build docker buildx command for multi-architecture
  build_cmd="docker buildx build $build_context --platform linux/amd64,linux/arm64 -t $REPO/$image_name:$TAG"

  # Add dockerfile if specified
  if [ -n "$dockerfile" ]; then
    build_cmd="$build_cmd -f $dockerfile"
  fi

  # Add push flag
  build_cmd="$build_cmd --push"

  # Execute build
  echo "Running: $build_cmd"
  eval "$build_cmd"

  # Get the manifest digest for the multi-arch image
  DIGEST=$(docker buildx imagetools inspect "$REPO/$image_name:$TAG" --format '{{.Manifest.Digest}}' 2>/dev/null || echo "")

  if [ -n "$DIGEST" ]; then
    DIGESTS+=("$image_name: docker.io/$REPO/$image_name:$TAG@$DIGEST")
  else
    DIGESTS+=("$image_name: docker.io/$REPO/$image_name:$TAG")
  fi

  # Get architecture-specific digests
  ARM64_DIGEST=$(docker buildx imagetools inspect "$REPO/$image_name:$TAG" --format '{{range .Manifest.Manifests}}{{if eq .Platform.Architecture "arm64"}}{{.Digest}}{{end}}{{end}}' 2>/dev/null || echo "")
  X86_64_DIGEST=$(docker buildx imagetools inspect "$REPO/$image_name:$TAG" --format '{{range .Manifest.Manifests}}{{if eq .Platform.Architecture "amd64"}}{{.Digest}}{{end}}{{end}}' 2>/dev/null || echo "")

  if [ -n "$ARM64_DIGEST" ]; then
    ARM64_IMAGES+=("arm64: docker.io/$REPO/$image_name:$TAG@$ARM64_DIGEST")
  fi

  if [ -n "$X86_64_DIGEST" ]; then
    X86_64_IMAGES+=("x86_64: docker.io/$REPO/$image_name:$TAG@$X86_64_DIGEST")
  fi
done


echo ""
echo "=== IMAGE DIGESTS ==="
for digest in "${DIGESTS[@]}"; do
  echo "$digest"
done

echo ""
echo "=== Log Output ==="
for arm_image in "${ARM64_IMAGES[@]}"; do
  echo "$arm_image"
done
for x86_image in "${X86_64_IMAGES[@]}"; do
  echo "$x86_image"
done

echo ""
echo "Multi-architecture build complete!"
echo "Images built for: linux/amd64, linux/arm64"
echo "These images will work on both ARM64 (local) and x86_64 (AKS) systems."