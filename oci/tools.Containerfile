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
ARG MGC_VERSION="0.23.0"
ARG OPENTOFU_VERSION="1.7.1"
ARG SPARK_VERSION="3.5.2"

# aws-cli
FROM public.ecr.aws/aws-cli/aws-cli:${AWS_CLI_VERSION} as awscli

# Tools downloader
FROM alpine as downloader
RUN apk add --no-cache curl unzip bash;
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
ARG MGC_VERSION
RUN curl -Lo mgc.tar.gz "https://github.com/MagaluCloud/mgccli/releases/download/v${MGC_VERSION}/mgccli_${MGC_VERSION}_linux_amd64.tar.gz" && \
    tar xzvf mgc.tar.gz && rm mgc.tar.gz && \
    ln -s "/tools/mgc" /usr/local/bin/mgc;
# bun (javascript runtime)
ENV BUN_INSTALL="/tools/bun"
RUN curl -fsSL https://bun.sh/install | bash && \
  ln -s /tools/bun/bin/bun /usr/local/bin/bun;
# OpenTofu
ARG OPENTOFU_VERSION
ENV OPENTOFU_VERSION=${OPENTOFU_VERSION}
RUN curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh;
RUN chmod +x install-opentofu.sh && \
  ./install-opentofu.sh --install-method standalone --install-path /tools/tofu --symlink-path - --skip-verify && \
  rm install-opentofu.sh;
# Spark with Hadoop
ARG SPARK_VERSION
ENV SPARK_VERSION=${SPARK_VERSION}
RUN curl -Lo spark.tgz "https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz" && \
  tar -xvzf spark.tgz && rm -rf spark.tgz && mv spark-${SPARK_VERSION}-bin-hadoop3 spark;

# Main image
FROM ubuntu:${UBUNTU_VERSION} as main
## aws
ARG AWS_CLI_VERSION
COPY --from=awscli /usr/local/aws-cli/ /tools/aws-cli/
RUN ln -s "/tools/aws-cli/v2/${AWS_CLI_VERSION}/bin/aws" /usr/local/bin/aws && \
    ln -s "/tools/aws-cli/v2/${AWS_CLI_VERSION}/bin/aws_completer" /usr/local/bin/aws_completer
# additional ubuntu packages
RUN apt update && apt install -y ca-certificates jq bc openssl curl python3 python3-pip less 
# rclone, dasel, gotpl, shellspec, mgc
COPY --from=downloader /tools/ /tools/
COPY --from=downloader /usr/local/bin/ /usr/local/bin/
RUN ln -s "/tools/tofu/tofu" /usr/local/bin/tofu

# java
RUN apt install -y openjdk-17-jre;

# poetry
RUN pip3 install poetry --break-system-packages;

# pandas
RUN apt install python3-pandas -y
