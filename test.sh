#!/bin/bash

# arguments
source ./vendor/yaacov/argparse.sh
define_arg "clients" "aws-s3api,aws-s3,rclone,mgc" "S3 clients that will perform the tests" "string" "false"
define_arg "profiles" "" "Profiles to use in the tests, must have the same name on all clients" "string" "true"
define_arg "tests" "" "A list of individual tests to perform" "string" "false"
set_description "Run tests on multiple S3 providers using multiple S3 clients."
check_for_help "$@"
parse_args "$@"

# convert comma separated lists to space separated
clients="${clients//,/ }"
profiles="${profiles//,/ }"
tests="${tests//,/ }"

# convert test numbers to test "id" tags
tag_args=""
for num in $tests; do
    padded_num=$(printf "%03d" $num)  # Padding each number with zeroes to three digits
    tag_args+=" --tag id:${padded_num}"
done

# use the env var EXTRA_ARGS if you need to pass more options to shellspec
shellspec --env CLIENTS="$clients" --env PROFILES="$profiles" -s bash $tag_args $EXTRA_ARGS
