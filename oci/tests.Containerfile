ARG TOOLS_IMAGE="ghcr.io/marmotitude/s3-tester:tools"

FROM ${TOOLS_IMAGE}

WORKDIR /app

#python poetry dependencies
COPY pyproject.toml poetry.lock /app/
ENV POETRY_VIRTUALENVS_IN_PROJECT=true
ENV POETRY_NO_INTERACTION=1
ENV SPARK_HOME=/tools/spark
RUN poetry install --only main;

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
