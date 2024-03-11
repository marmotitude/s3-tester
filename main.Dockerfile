ARG UBUNTU_VERSION="24.04"
# Full list of versions at https://raw.githubusercontent.com/aws/aws-cli/v2/CHANGELOG.rst
ARG AWS_CLI_VERSION="2.15.27"
ARG AWS_CLI_DEPENDENCIES="groff"

FROM ubuntu:${UBUNTU_VERSION}
ARG AWS_CLI_VERSION
ARG AWS_CLI_DEPENDENCIES
RUN apt update && \
    apt install -y \
      curl unzip \
      ${AWS_CLI_DEPENDENCIES}
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install --bin-dir /aws-cli-bin/
ENV PATH "/aws-cli-bin:${PATH}"

