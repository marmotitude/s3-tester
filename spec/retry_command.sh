#!/bin/bash

command=$1
timeout_duration=${2:-20} # Tempo máximo de execução em segundos (240 = 4 minutos)

end_time=$((SECONDS + timeout_duration))

while true; do
  # Verifica se o tempo limite foi alcançado
  if [ $SECONDS -ge $end_time ]; then
    echo "Timeout de $timeout_duration segundos alcançado. O comando: $command não foi concluído dentro do prazo."
    exit 1
  fi

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

  if echo "$output" | grep -q "Forbidden"; then
    echo "Forbidden detected. retrying..."
    sleep 1
    continue
  fi

  echo "Unexpected error: $output"
  exit 1
done
