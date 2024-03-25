# This OCI image contains the required tools to run the tests: awscli, rclone, mgc and shellspec
# you can use it with distrobox to have a quick "all-in-one" environment for executing them
# or as a basis for other images that want to include the compatibility tests

# Build arguments, versions of the pieces
ARG UBUNTU_VERSION="24.04"
ARG SHELLSPEC_VERSION="0.28.1"
ARG AWS_CLI_VERSION="2.15.27"
ARG RCLONE_VERSION="1.66.0"

# Main image
FROM ubuntu:${UBUNTU_VERSION}
RUN apt update && \
    apt install -y \
      curl git unzip

WORKDIR /downloads

# shellspec
ARG SHELLSPEC_VERSION
RUN curl -fsSL https://git.io/shellspec | sh -s ${SHELLSPEC_VERSION} -y -p "/tools/shellspec"
ENV PATH "/tools/shellspec/bin:${PATH}"

# aws-cli
ARG AWS_CLI_VERSION
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install --bin-dir /tools/aws-cli/
ENV PATH "/tools/aws-cli:${PATH}"

# rlone
ARG RCLONE_VERSION
RUN curl "https://downloads.rclone.org/v${RCLONE_VERSION}/rclone-v${RCLONE_VERSION}-linux-amd64.zip" -o rclone.zip && \
    unzip -a rclone.zip -d "/tools"
ENV PATH "/tools/rclone-v${RCLONE_VERSION}-linux-amd64:${PATH}"

# mgc
# TODO: download an specific version from a canonical distribution url
#       like the Github releases page, when it becomes available
#       for now, we are including the binary in the repo
COPY vendor/mgc/mgc_latest /tools/mgc/mgc
ENV PATH "/tools/mgc:${PATH}"
