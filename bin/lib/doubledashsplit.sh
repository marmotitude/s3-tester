#!/bin/bash

# Find the position of the "--"
double_dash_position=$#+1
for (( i=1; i<=$#; i++ )); do
    if [ "${!i}" = "--" ]; then
        double_dash_position=$i
        break
    fi
done
# Capture arguments before and after "--"
args_before_double_dash="${@:1:double_dash_position-1}"
args_after_double_dash="${@:double_dash_position+1}"

