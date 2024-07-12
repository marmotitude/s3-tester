FROM ghcr.io/marmotitude/s3-tester:tools

WORKDIR /app

# tests
COPY spec spec
COPY .shellspec .shellspec

# test files
COPY README.md README.md
COPY LICENSE LICENSE
COPY profiles.example.yaml profiles.example.yaml

# scripts
COPY bin bin
COPY vendor/yaacov/argparse.sh vendor/yaacov/argparse.sh

# uncomment the line below to use a custom mgc build
#COPY vendor/MagaluCloud/mgc /usr/local/bin/mgc

# config templates and entrypoint
COPY templates /app/templates
RUN chmod +x /app/bin/webhook.py

#js bun dependencies
COPY package.json bun.lockb /app/
RUN bun install --frozen-lockfile --production

ENV PROFILES=$PROFILES
ENV PATH "/app/bin:${PATH}"

COPY oci/tests.entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
