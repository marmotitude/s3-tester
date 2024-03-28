FROM ghcr.io/marmotitude/s3-tester:tools

WORKDIR /app
ENV PATH "/app:${PATH}"
COPY test.sh test.sh
COPY spec spec
COPY vendor/yaacov/argparse.sh vendor/yaacov/argparse.sh
#TODO we need a way to generate the profiles inside the container
