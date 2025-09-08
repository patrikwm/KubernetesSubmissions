#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ./build_and_push.sh <tag> [app1,app2,...]
# ./build_and_push.sh 1.12                    # Build all apps
# ./build_and_push.sh 1.12 pingpong          # Build only pingpong
# ./build_and_push.sh 1.12 pingpong,todo-app # Build pingpong and todo-app

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  echo "Usage: $0 <tag> [app1,app2,...]"
  echo ""
  echo "Available apps: todo-app, pingpong, log-reader, log-writer, todo-backend"
  echo ""
  echo "Examples:"
  echo "  $0 1.12                    # Build all apps"
  echo "  $0 1.12 pingpong          # Build only pingpong"
  echo "  $0 1.12 pingpong,todo-app # Build pingpong and todo-app"
  exit 1
fi

TAG=$1
SELECTED_APPS=${2:-"all"}
REPO="pjmartin"

echo "Building and pushing multi-architecture images with tag: $TAG"

if [ "$SELECTED_APPS" = "all" ]; then
  echo "Building all applications..."
else
  echo "Building selected applications: $SELECTED_APPS"
fi

# Create and use a new buildx builder instance for multi-arch builds
echo "Setting up Docker buildx for multi-architecture builds..."
docker buildx create --name multiarch-builder --use --bootstrap || docker buildx use multiarch-builder

# Array to store image digests
declare -a DIGESTS=()
declare -a ARM64_IMAGES=()
declare -a X86_64_IMAGES=()

# Define applications to build
# Format: "image_name:build_context:dockerfile_path"
ALL_APPS=(
  "todo-app:./todo-app:"
  "pingpong:./ping-pong_application:"
  "log-reader:./log_output:./log_output/Dockerfile.read"
  "log-writer:./log_output:./log_output/Dockerfile.write"
  "todo-backend:./todo-backend:"
)

# Function to check if an app should be built
should_build_app() {
  local app_name=$1
  if [ "$SELECTED_APPS" = "all" ]; then
    return 0
  fi

  # Convert comma-separated list to array and check if app is in the list
  IFS=',' read -ra SELECTED_APP_ARRAY <<< "$SELECTED_APPS"
  for selected in "${SELECTED_APP_ARRAY[@]}"; do
    if [ "$selected" = "$app_name" ]; then
      return 0
    fi
  done
  return 1
}

# Build selected applications
APPS_TO_BUILD=()
for app_config in "${ALL_APPS[@]}"; do
  IFS=':' read -r image_name build_context dockerfile <<< "$app_config"
  if should_build_app "$image_name"; then
    APPS_TO_BUILD+=("$app_config")
  fi
done

if [ ${#APPS_TO_BUILD[@]} -eq 0 ]; then
  echo "Error: No valid applications selected"
  echo "Available apps: todo-app, pingpong, log-reader, log-writer, todo-backend"
  exit 1
fi

echo "Apps to build: ${#APPS_TO_BUILD[@]}"

# Build and push each application
for app_config in "${APPS_TO_BUILD[@]}"; do
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