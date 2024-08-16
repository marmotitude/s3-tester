#!/bin/bash

command=$1
timeout_duration=10 # Tempo máximo de execução em segundos (240 = 4 minutos)

while true; do
  output=$(timeout $timeout_duration $command 2>&1)
  status=$?

  if [ $status -eq 0 ]; then
    echo "$output"
    exit 0
  fi

  if [ $status -eq 124 ]; then
    echo "Timeout de $timeout_duration segundos alcançado. O comando $command não foi concluído dentro de $timeout_duration segundos."
    exit 1
  fi

  if echo "$output" | grep -q "connection reset by peer"; then
    echo "Connection reset by peer detected, retrying..."
    sleep 1
    continue
  fi

  if echo "$output" | grep -q "AccessDenied"; then
    echo "AccessDenied error detected. retrying..."
    sleep 1
    continue
  fi

  if echo "$output" | grep -q "BucketNotEmpty"; then
    echo "BucketNotEmpty detected. retrying..."
    sleep 1
    continue
  fi

  echo "Unexpected error: $output"
  exit 1
done
