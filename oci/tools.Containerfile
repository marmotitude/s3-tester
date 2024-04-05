# Overview
#
# This OCI image contains the following tools used by the tests:
# dasel, gotpl, shellspec, awscli, rclone, mgccli

# Build args
# version of the base image
#ARG UBUNTU_VERSION="22.04" # LTS until 2027
ARG UBUNTU_VERSION="24.04"
# version of the tools
ARG DASEL_VERSION="2.7.0"
ARG GOTPL_VERSION="0.7"
ARG SHELLSPEC_VERSION="0.28.1"
ARG AWS_CLI_VERSION="2.15.27"
ARG RCLONE_VERSION="1.66.0"
ARG MGC_VERSION="0.18.4-rc6"

# aws-cli
FROM public.ecr.aws/aws-cli/aws-cli:${AWS_CLI_VERSION} as awscli

# Tools downloader
FROM alpine as downloader
RUN apk add --no-cache curl unzip
WORKDIR /tools
# rclone
ARG RCLONE_VERSION
RUN curl -Lo rclone.zip "https://downloads.rclone.org/v${RCLONE_VERSION}/rclone-v${RCLONE_VERSION}-linux-amd64.zip" && \
    unzip -a rclone.zip && rm rclone.zip && \
    ln -s "/tools/rclone-v${RCLONE_VERSION}-linux-amd64/rclone" /usr/local/bin/rclone
# dasel
ARG DASEL_VERSION
RUN curl -Lo dasel -sSf "$(curl -sSLf https://api.github.com/repos/tomwright/dasel/releases/tags/v${DASEL_VERSION} | grep browser_download_url | grep linux_amd64 | grep -v .gz | cut -d\" -f 4)" && \
    chmod +x dasel && \
    ln -s "/tools/dasel" /usr/local/bin/dasel
# gotpl
ARG GOTPL_VERSION
RUN curl -Lo gotpl.zip "https://github.com/belitre/gotpl/releases/download/v${GOTPL_VERSION}/gotpl-v${GOTPL_VERSION}-linux-amd64.zip" && \
    unzip gotpl.zip -d "/tools/gotpl" && rm gotpl.zip && \
    ln -s "/tools/gotpl/linux-amd64/gotpl" /usr/local/bin/gotpl
# shellspec
ARG SHELLSPEC_VERSION
RUN curl -Lo shellspec.tar.gz "https://github.com/shellspec/shellspec/archive/${SHELLSPEC_VERSION}.tar.gz" && \
    tar xzvf shellspec.tar.gz && rm shellspec.tar.gz && \
    ln -s "/tools/shellspec-${SHELLSPEC_VERSION}/shellspec" /usr/local/bin/
# mgc
# TODO: download an specific version from a canonical distribution url
#       like the Github releases page, when it becomes available
#       for now, we are including the binary in the repo
ARG MGC_VERSION
COPY "vendor/mgc/mgccli_${MGC_VERSION}_linux_amd64.tar.gz" /tools/mgc.tar.gz
RUN tar xzvf mgc.tar.gz && rm mgc.tar.gz && \
    ln -s "/tools/mgc" /usr/local/bin/mgc

# Main image
FROM ubuntu:${UBUNTU_VERSION} as main
## aws
ARG AWS_CLI_VERSION
COPY --from=awscli /usr/local/aws-cli/ /tools/aws-cli/
RUN ln -s "/tools/aws-cli/v2/${AWS_CLI_VERSION}/bin/aws" /usr/local/bin/aws && \
    ln -s "/tools/aws-cli/v2/${AWS_CLI_VERSION}/bin/aws_completer" /usr/local/bin/aws_completer
# jq, openssl
RUN apt update && apt install -y jq openssl
# rclone, dasel, gotpl, shellspec, mgc
COPY --from=downloader /tools/ /tools/
COPY --from=downloader /usr/local/bin/ /usr/local/bin/

