#!/usr/bin/env bash
IMAGE_TO_TEST="${1:-debian}"
RUN_ONE="${2:-false}" # false or script name
USE_DEFAULTS="${3:-true}"
RUN_COMMON_SCRIPT="${4:-true}"
PLATFORMS="$5"

if [[ "${IMAGE_TO_TEST}" = *"alpine"* ]]; then
    DISTRO="alpine"
elif [[ "$IMAGE_TO_TEST" = *"centos"* ]] || [[ "$IMAGE_TO_TEST" = *"redhat"* ]]; then
    DISTRO="redhat"
else
    DISTRO="debian"
fi

set -e

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.."
echo -e  "🧪 Testing image $IMAGE_TO_TEST (${DISTRO}-like)..."

if [ ! -z "${PLATFORMS}" ]; then
    CURRENT_BUILDERS="$(docker buildx ls)"
    if [[ "${CURRENT_BUILDERS}" != *"vscode-dev-containers"* ]]; then
        docker buildx create --use --name vscode-dev-containers
    else
        docker buildx use vscode-dev-containers
    fi

    docker run --privileged --rm tonistiigi/binfmt --install ${PLATFORMS}
    PLATFORMS_ARG="--builder vscode-dev-containers --platform ${PLATFORMS}"
fi
BUILDX_COMMAND="docker buildx build \
    --load \
    ${PLATFORMS_ARG} \
    --progress=plain \
    --build-arg DISTRO=$DISTRO \
    --build-arg IMAGE_TO_TEST=$IMAGE_TO_TEST \
    --build-arg RUN_ONE=${RUN_ONE} \
    --build-arg RUN_COMMON_SCRIPT=${RUN_COMMON_SCRIPT} \
    --build-arg USE_DEFAULTS=${USE_DEFAULTS}
    -t vscdc-script-library-regression \
    -f test/regression/Dockerfile \
    ."
echo $BUILDX_COMMAND
$BUILDX_COMMAND
docker run --init --privileged vscdc-script-library-regression bash -c 'uname -m && env'

echo -e "\n🎉 All tests passed!"
