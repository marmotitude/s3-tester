# start with tools
FROM ghcr.io/marmotitude/s3-tester:tools as base_tools

ARG TERRAFORM_VERSION="1.8.2-1"
ARG OPENTOFU_VERSION="1.7.1"

# add Terraform on top
ARG TERRAFORM_VERSION
RUN apt install wget lsb-release;
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg;
RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | tee /etc/apt/sources.list.d/hashicorp.list && \
  apt update && apt install -y terraform=${TERRAFORM_VERSION};

# add OpenTofu on top
ARG OPENTOFU_VERSION
ENV OPENTOFU_VERSION=${OPENTOFU_VERSION}
RUN curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh;
RUN chmod +x install-opentofu.sh && \
  ./install-opentofu.sh --install-method deb && \
  rm install-opentofu.sh;
