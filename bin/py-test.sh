#!/bin/bash
SCRIPT_PATH="$( cd "$( echo "${BASH_SOURCE[0]%/*}" )" && pwd )"

# split arguments before and after double dash
source "$SCRIPT_PATH/lib/doubledashsplit.sh"

# arguments
source "$SCRIPT_PATH/../vendor/yaacov/argparse.sh"
define_arg "profiles" "" "Profiles to use in the tests" "string" "true"
set_description "Run pytest tests setting up aws env vars first for each profile.\nUse -- [pytest args...] in the end to pass more arguments to pytest.\nExample: ./py-test.sh --profiles br-ne1 -- --verbose"

check_for_help $args_after_double_dash
parse_args $args_before_double_dash

# convert comma separated lists to space separated
profiles="${profiles//,/ }"

for profile in $profiles;do
  echo $profile
  AWS_PROFILE="$profile" poetry run pytest $args_after_double_dash
done
