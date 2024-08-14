#!/bin/bash

command=$1

while true; do
  output=$($command 2>&1)
  status=$?

  if [ $status -eq 0 ]; then
    echo "$output"
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


#When run bash ./spec/retry_command.sh "mgc object-storage buckets create "$bucket_name""
#When run bash ./spec/retry_command.sh "mgc object-storage buckets create "$bucket_name-$client""

#When run bash ./spec/retry_command.sh "mgc object-storage buckets delete "$bucket_name" --no-confirm --raw"
#The output should equal ""
