#!/bin/bash

# create profiles
echo "$PROFILES" > profiles.yaml
replace_configs.sh

# run the main script
test.sh "$@"
