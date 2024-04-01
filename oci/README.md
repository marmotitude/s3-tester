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

```sh
# podman run if you use podman
docker run -t -e PROFILES="$(cat profiles.yaml)" ghcr.io/marmotitude/s3-tester:tests --profiles default --clients aws,mgc --tests 1,2,53,64
```



