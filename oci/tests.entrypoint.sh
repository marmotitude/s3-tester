#!/bin/bash

# create profiles
echo "$PROFILES" > profiles.yaml
bin/replace_configs.sh

# run the main script
$@
