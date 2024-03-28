FROM ghcr.io/marmotitude/s3-tester:tools

WORKDIR /app

# tests
COPY spec spec
COPY .shellspec .shellspec

# test files
COPY README.md README.md
COPY LICENSE LICENSE

# scripts
COPY test.sh test.sh
COPY vendor/yaacov/argparse.sh vendor/yaacov/argparse.sh

# config templates and entrypoint
COPY templates /app/templates
COPY oci/tests.entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENV PROFILES=$PROFILES
ENV PATH "/app:${PATH}"
ENTRYPOINT ["/app/entrypoint.sh"]
