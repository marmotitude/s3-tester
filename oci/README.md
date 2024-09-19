# Running S3 Tester from an all-in-one OCI image

## 1. copy profiles.example.yaml file to profiles.yaml and edit it

```sh
cp profiles.example.yaml profiles.yaml
vim profiles.yaml # or your editor of choice
```

## 2. pull the latest "tests" image

OCI images are frequently published here: https://github.com/marmotitude/s3-tester/pkgs/container/s3-tester/versions

```sh
# podman pull if you use podman
docker pull ghcr.io/marmotitude/s3-tester:tests #get latest "tests" image
```

## 3. run the tests

The image will use a `PROFILES` env var to set the profiles inside the container

(shellspec)

```sh
# podman run if you use podman
docker run -t -e PROFILES="$(cat profiles.yaml)" ghcr.io/marmotitude/s3-tester:tests test.sh --profiles default --clients aws,mgc --tests 1,2,53,64
```

(bun test)

```sh
# podman run if you use podman
docker run -t -e PROFILES="$(cat profiles.yaml)" ghcr.io/marmotitude/s3-tester:tests js-test.sh --profiles br-ne1
```

## 4. run benchmark test

The image will use a `PROFILES` env var to set the profiles inside the container

(shellspec)

```sh
# podman run if you use podman
docker run -t   -e PROFILES="$(cat profiles.yaml)"   -v ./report:/app/report   ghcr.io/marmotitude/s3-tester:tests   benchmark-test.sh --profiles profile1 --tests 100 --clients aws --sizes 1,2,3 --quantity 1,2,3 --workers 64 --times 10
```

The html output saved to you local path /report
