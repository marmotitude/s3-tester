#!/bin/bash

profile=$1
bucket_name=$2
command=$3
sub_command=$4

while true; do
  output=$(mgc object-storage "$command" "$sub_command" "$bucket_name" --raw 2>&1)
  status=$?

  if [ $status -eq 0 ]; then
    echo "Bucket "$bucket_name" created successfully!"
    exit 0
  fi

  if echo "$output" | grep -q "connection reset by peer"; then
    echo "Connection reset by peer detected, retrying..."
    sleep 1
    continue
  fi

  echo "Unexpected error: $output"
  exit 1
done
