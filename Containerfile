# Allow build scripts to be referenced without being copied into the final image.
FROM scratch AS ctx
COPY build_files /

# Keep Bluefin DX GNOME NVIDIA Open as the base image.
FROM ghcr.io/ublue-os/bluefin-dx-nvidia-open:stable

# Apply image customizations.
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

# Verify final image and bootc metadata.
RUN bootc container lint
