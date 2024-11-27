# Função para medir o tempo de uma operação
measure_time() {
    start=$(date +%s%3N)
    "$@" > /dev/null
    end=$(date +%s%3N)
    runtime=$((end - start))
    echo "$runtime"
}

Describe 'Benchmark test:' category:"BucketManagement"
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
    test_bucket_name="$bucket_name-$client-$profile"
    printf "\n$test_bucket_name" >> ./report/buckets_to_delete.txt
    sizes=$3 #param
    quantity=$4 #param
    times=$5 #param
    workers=$6 #param
    date=$7
    aws --profile "$profile" s3 mb s3://"$test_bucket_name" > /dev/null
    for size in $(echo $sizes | tr "," "\n")
    do
      for i in $(seq 1 $quantity); do
          if [ ! -d "temp-report-${size}k-${quantity}" ]; then
            mkdir "temp-report-${size}k-${quantity}" > /dev/null
            echo "Diretório 'temp-report-${size}k-${quantity}' criado." > /dev/null
          else
              echo "Diretório 'temp-report-${size}k-${quantity}' já existe." > /dev/null
          fi
        fallocate -l "${size}k" "./temp-report-${size}k-${quantity}/arquivo_${size}k_$i.txt"
      done
      case "$client" in
        "aws-s3api" | "aws" | "aws-s3")
          printf "\n%s,%s,%s,upload,%s,%s,%s,%s" "$date" "$profile" "$client" "$size" "$times" "$workers" "$quantity," >> ./report/benchmark.csv
          for i in $(seq 1 $times); do
            time=$(measure_time aws --profile $profile s3 cp ./temp-report-${size}k-${quantity} s3://$test_bucket_name/${size}k-${quantity}/$i/ --recursive)
            printf "%s," "$time" >> ./report/benchmark.csv
          done
          printf "\n%s,%s,%s,download,%s,%s,%s,%s" "$date" "$profile" "$client" "$size" "$times" "$workers" "$quantity," >> ./report/benchmark.csv
          for i in $(seq 1 $times); do
            time=$(measure_time aws --profile $profile s3 cp s3://$test_bucket_name/${size}k-${quantity}/$i/ ./$test_bucket_name-$size-$quantity-$i --recursive)
            printf "%s," "$time" >> ./report/benchmark.csv
            rm -rf test-*
          done
          printf "\n%s,%s,%s,delete,%s,%s,%s,%s" "$date" "$profile" "$client" "$size" "$times" "$workers" "$quantity," >> ./report/benchmark.csv
          for i in $(seq 1 $times); do
            time=$(measure_time aws --profile $profile s3 rm s3://$test_bucket_name/${size}k-${quantity}/$i/ --recursive)
            printf "%s," "$time" >> ./report/benchmark.csv
          done
          ;;
        "rclone")
          printf "\n%s,%s,%s,upload,%s,%s,%s,%s" "$date" "$profile" "$client" "$size" "$times" "$workers" "$quantity," >> ./report/benchmark.csv
          for i in $(seq 1 $times); do
            time=$(measure_time rclone copy ./temp-report-${size}k-${quantity} $profile:$test_bucket_name/${size}k-${quantity}/$i/ --transfers=$workers)
            printf "%s," "$time" >> ./report/benchmark.csv
          done
          printf "\n%s,%s,%s,download,%s,%s,%s,%s" "$date" "$profile" "$client" "$size" "$times" "$workers" "$quantity," >> ./report/benchmark.csv
          for i in $(seq 1 $times); do
            time=$(measure_time rclone copy $profile:$test_bucket_name/${size}k-${quantity}/$i/ ./$test_bucket_name-$size-$quantity-$i --transfers=$workers)
            printf "%s," "$time" >> ./report/benchmark.csv
            rm -rf test-*
          done
          printf "\n%s,%s,%s,delete,%s,%s,%s,%s" "$date" "$profile" "$client" "$size" "$times" "$workers" "$quantity," >> ./report/benchmark.csv
          for i in $(seq 1 $times); do
            time=$(measure_time rclone delete $profile:$test_bucket_name/${size}k-${quantity}/$i/)
            printf "%s," "$time" >> ./report/benchmark.csv
          done
          ;;
        "mgc")
          printf "\n%s,%s,%s,upload,%s,%s,%s,%s" "$date" "$profile" "$client" "$size" "$times" "$workers" "$quantity," >> ./report/benchmark.csv
          mgc workspace set "$profile" > /dev/null
          for i in $(seq 1 $times); do
            time=$(measure_time mgc object-storage objects upload-dir ./temp-report-${size}k-${quantity} $test_bucket_name/${size}k-${quantity}/$i/ --workers $workers)
            printf "%s," "$time" >> ./report/benchmark.csv
          done
          printf "\n%s,%s,%s,download,%s,%s,%s,%s" "$date" "$profile" "$client" "$size" "$times" "$workers" "$quantity," >> ./report/benchmark.csv
          for i in $(seq 1 $times); do
            time=$(measure_time mgc object-storage objects download-all $test_bucket_name/${size}k-${quantity}/$i/ ./$test_bucket_name-$size-$quantity-$i)
            printf "%s," "$time" >> ./report/benchmark.csv
            rm -rf test-*
          done
          printf "\n%s,%s,%s,delete,%s,%s,%s,%s" "$date" "$profile" "$client" "$size" "$times" "$workers" "$quantity," >> ./report/benchmark.csv
          for i in $(seq 1 $times); do
            time=$(measure_time mgc object-storage objects delete-all $test_bucket_name/${size}k-${quantity}/$i/ --no-confirm)
            printf "%s," "$time" >> ./report/benchmark.csv
          done
          ;;
      esac
      rm -rf temp-report*
    done
    rclone purge $profile:$test_bucket_name > /dev/null
    python3 ./bin/process_data.py
    python3 ./bin/benchmark.py
    aws s3 --profile br-se1 cp ./report/benchmark.csv s3://benchmark/data/${date}h.csv --acl public-read > /dev/null
    aws s3 --profile br-se1 cp ./report/${date}h-processed_data.csv s3://benchmark/processed_data/${date}h.csv --acl public-read > /dev/null
    aws s3 --profile br-se1 cp ./report/${date}h-dashboard.html s3://benchmark/dashboards/${date}h-dashboard.html --acl public-read > /dev/null
    aws s3 --profile br-se1 cp ./report/${date}h-dashboard.html s3://benchmark/dashboards/index.html --acl public-read > /dev/null
  End
End
