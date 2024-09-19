# Função para medir o tempo de uma operação
measure_time() {
    start=$(date +%s%3N)
    "$@" > /dev/null
    end=$(date +%s%3N)
    runtime=$((end - start))
    echo "$runtime"
}

Describe 'Benchmark test:' category:"Bucket Management"
  setup() {
    bucket_name="test-100-$(date +%s)"
  }

  Before 'setup'
    Parameters:matrix
      $PROFILES
      $CLIENTS
      $SIZES
      $QUANTITY
      $TIMES
      $WORKERS
      $DATE
    End

  Example "on profile $1 using client $2" id:"100"
    profile=$1
    client=$2
    sizes=$3 #param
    quantity=$4 #param
    times=$5 #param
    workers=$6 #param
    date=$7
    aws --profile "$profile" s3 mb s3://"$bucket_name-$client" > /dev/null
    for size in $(echo $sizes | tr "," "\n")
    do
    if [ ! -d "temp-report-${size}k" ]; then
        mkdir "temp-report-${size}k" > /dev/null
        echo "Diretório 'temp-report-${size}k' criado." > /dev/null
    else
        echo "Diretório 'temp-report-${size}k' já existe." > /dev/null
    fi
      for i in $(seq 1 $quantity); do
        fallocate -l "${size}k" "./temp-report-${size}k/arquivo_${size}k_$i.txt"
      done
      #echo "" >> ./report/benchmark.csv
      #echo "$date,$profile,$client" >> ./report/benchmark.csv
      case "$client" in
        "aws-s3api" | "aws" | "aws-s3")
          aws configure set s3.max_concurrent_requests $workers --profile $profile
          printf "\n%s,%s,%s,upload,%s,%s,%s,%s" "$date" "$profile" "$client" "$size" "$times" "$workers" "$quantity," >> ./report/benchmark.csv
          for i in $(seq 1 $times); do
            time=$(measure_time aws --profile $profile s3 sync ./temp-report-${size}k s3://$bucket_name-$client)
            printf "%s," "$time" >> ./report/benchmark.csv
          done
          aws configure set s3.max_concurrent_requests $workers --profile $profile
          printf "\n%s,%s,%s,download,%s,%s,%s,%s" "$date" "$profile" "$client" "$size" "$times" "$workers" "$quantity," >> ./report/benchmark.csv
          for i in $(seq 1 $times); do
            time=$(measure_time aws --profile $profile s3 sync s3://$bucket_name-$client ./$bucket_name-$client)
            printf "%s," "$time" >> ./report/benchmark.csv
          done
          aws configure set s3.max_concurrent_requests $workers --profile $profile
          printf "\n%s,%s,%s,update,%s,%s,%s,%s" "$date" "$profile" "$client" "$size" "$times" "$workers" "$quantity," >> ./report/benchmark.csv
          for i in $(seq 1 $times); do
            time=$(measure_time aws --profile $profile s3 sync ./temp-report-${size}k s3://$bucket_name-$client)
            printf "%s," "$time" >> ./report/benchmark.csv
          done
          aws configure set s3.max_concurrent_requests $workers --profile $profile
          printf "\n%s,%s,%s,delete,%s,%s,%s,%s" "$date" "$profile" "$client" "$size" "$times" "$workers" "$quantity," >> ./report/benchmark.csv
          for i in $(seq 1 $times); do
            time=$(measure_time aws --profile $profile s3 rm s3://$bucket_name-$client --recursive)
            printf "%s," "$time" >> ./report/benchmark.csv
          done
          ;;
        "rclone")
          printf "\n%s,%s,%s,upload,%s,%s,%s,%s" "$date" "$profile" "$client" "$size" "$times" "$workers" "$quantity," >> ./report/benchmark.csv
          for i in $(seq 1 $times); do
            time=$(measure_time rclone sync ./temp-report-${size}k $profile:$bucket_name-$client --transfers=$workers)
            printf "%s," "$time" >> ./report/benchmark.csv
          done
          printf "\n%s,%s,%s,download,%s,%s,%s,%s" "$date" "$profile" "$client" "$size" "$times" "$workers" "$quantity," >> ./report/benchmark.csv
          for i in $(seq 1 $times); do
            time=$(measure_time rclone sync $profile:$bucket_name-$client ./$bucket_name-$client --transfers=$workers)
            printf "%s," "$time" >> ./report/benchmark.csv
          done
          printf "\n%s,%s,%s,update,%s,%s,%s,%s" "$date" "$profile" "$client" "$size" "$times" "$workers" "$quantity," >> ./report/benchmark.csv
          for i in $(seq 1 $times); do
            time=$(measure_time rclone sync ./temp-report-${size}k $profile:$bucket_name-$client --transfers=$workers)
            printf "%s," "$time" >> ./report/benchmark.csv
          done
          printf "\n%s,%s,%s,delete,%s,%s,%s,%s" "$date" "$profile" "$client" "$size" "$times" "$workers" "$quantity," >> ./report/benchmark.csv
          for i in $(seq 1 $times); do
            time=$(measure_time rclone delete $profile:$bucket_name-$client)
            printf "%s," "$time" >> ./report/benchmark.csv
          done
          ;;
        "mgc")
          printf "\n%s,%s,%s,upload,%s,%s,%s,%s" "$date" "$profile" "$client" "$size" "$times" "$workers" "$quantity," >> ./report/benchmark.csv
          mgc profile set "$profile" > /dev/null
          for i in $(seq 1 $times); do
            time=$(measure_time mgc object-storage objects sync ./temp-report-${size}k $bucket_name-$client --workers $workers)
            printf "%s," "$time" >> ./report/benchmark.csv
          done
          printf "\n%s,%s,%s,download,%s,%s,%s,%s" "$date" "$profile" "$client" "$size" "$times" "$workers" "$quantity," >> ./report/benchmark.csv
          for i in $(seq 1 $times); do
            time=$(measure_time mgc object-storage objects download-all $bucket_name-$client ./$bucket_name-$client)
            printf "%s," "$time" >> ./report/benchmark.csv
          done
          printf "\n%s,%s,%s,update,%s,%s,%s,%s" "$date" "$profile" "$client" "$size" "$times" "$workers" "$quantity," >> ./report/benchmark.csv
          for i in $(seq 1 $times); do
            time=$(measure_time mgc object-storage objects sync ./temp-report-${size}k $bucket_name-$client --workers $workers)
            printf "%s," "$time" >> ./report/benchmark.csv
          done
          printf "\n%s,%s,%s,delete,%s,%s,%s,%s" "$date" "$profile" "$client" "$size" "$times" "$workers" "$quantity," >> ./report/benchmark.csv
          for i in $(seq 1 $times); do
            time=$(measure_time mgc object-storage objects delete-all $bucket_name-$client/arquivo_${size}M_$i.txt --no-confirm)
            printf "%s," "$time" >> ./report/benchmark.csv
          done
          ;;
      esac
    done
    rclone purge $profile:$bucket_name-$client > /dev/null
    python3 ./bin/process_data.py
    python3 ./bin/benchmark.py
    aws s3 --profile br-se1 cp ./report/benchmark.csv s3://benchmark/data/${date}h.csv --acl public-read > /dev/null
    aws s3 --profile br-se1 cp ./report/${date}h-processed_data.csv s3://benchmark/processed_data/${date}h.csv --acl public-read > /dev/null
    aws s3 --profile br-se1 cp ./report/${date}h-dashboard.html s3://benchmark/dashboards/${date}h-dashboard.html --acl public-read > /dev/null
    aws s3 --profile br-se1 cp ./report/${date}h-dashboard.html s3://benchmark/dashboards/index.html --acl public-read > /dev/null
  End
End
