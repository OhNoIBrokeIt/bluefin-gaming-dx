export image_name := env("IMAGE_NAME", "bluefin-gaming-dx")
export default_tag := env("DEFAULT_TAG", "latest")

[private]
default:
    @just --list

[group("Build")]
build target_image=image_name tag=default_tag:
    #!/usr/bin/env bash
    set -euo pipefail
    BUILD_ARGS=()
    if [[ -z "$(git status -s 2>/dev/null)" ]]; then
      BUILD_ARGS+=("--build-arg" "SHA_HEAD_SHORT=$(git rev-parse --short HEAD 2>/dev/null)")
    fi
    podman build \
      "${BUILD_ARGS[@]}" \
      --pull=newer \
      --tag "${target_image}:${tag}" \
      .

[group("Build")]
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v shellcheck >/dev/null; then
      echo "shellcheck is required for lint"
      exit 1
    fi
    shellcheck build_files/*.sh

[group("Utility")]
clean:
    #!/usr/bin/env bash
    set -euo pipefail
    rm -rf output/ *_build* previous.manifest.json changelog.md output.env
