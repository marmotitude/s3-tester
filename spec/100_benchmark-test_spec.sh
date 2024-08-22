# Função para medir o tempo de uma operação
measure_time() {
    start=$(date +%s.%N)
    "$@" > /dev/null
    end=$(date +%s.%N)
    runtime=$(echo "$end - $start" | bc)
    echo "$runtime"
}

Describe 'Benchmark test:' category:"Bucket Management"
  setup() {
    bucket_name="test-100-$(date +%s)"
    date=$(date +%s.%N)
  }

  Before 'setup'
    Parameters:matrix
      $PROFILES
      $CLIENTS
      $SIZES
      $QUANTITY
    End

  Example "on profile $1 using client $2" id:"100"
    profile=$1
    client=$2
    sizes=$3 #param
    quantity=$4 #param
    aws --profile "$profile" s3 mb s3://"$bucket_name-$client" > /dev/null
    for size in $(echo $sizes | tr "," "\n")
    do
      for i in $(seq 1 $quantity); do
        fallocate -l "${size}M" "./report/arquivo_${size}M_$i.txt"
      done
      echo $date,$profile,$client,$size>> ./report/benchmark.csv
      case "$client" in
        "aws-s3api" | "aws" | "aws-s3")
          for i in $(seq 1 $quantity); do
            time=$(measure_time aws --profile $profile s3 cp ./report/arquivo_$i.txt s3://$bucket_name-$client)
            printf ",create%d,%s" "$i" "$time" >> ./report/benchmark.csv
          done
          for i in $(seq 1 $quantity); do
            time=$(measure_time aws --profile $profile s3 cp s3://$bucket_name-$client/arquivo_$i.txt ./$bucket_name-$client/arquivo_$i.txt)
            printf ",download%d,%s" "$i" "$time" >> ./report/benchmark.csv
          done
          for i in $(seq 1 $quantity); do
            time=$(measure_time aws --profile $profile s3 cp ./report/arquivo_$i.txt s3://$bucket_name-$client)
            printf ",update%d,%s,%s" "$i" "$time" >> ./report/benchmark.csv
          done
          for i in $(seq 1 $quantity); do
            time=$(measure_time aws --profile $profile s3 rm s3://$bucket_name-$client/arquivo_$i.txt)
            printf ",delete%d,%s" "$i" "$time" >> ./report/benchmark.csv
          done
          ;;
        "rclone")
          for i in $(seq 1 $quantity); do
            create_time=$(measure_time rclone s3 copy ./report/arquivo_$i.txt $profile:$bucket_name-$client)
            printf ",create%d,%s" "$i" "$time" >> ./report/benchmark.csv
          done
          for i in $(seq 1 $quantity); do
            download_time=$(measure_time rclone copy $profile:$bucket_name-$client/arquivo_$i.txt ./$bucket_name-$client/arquivo_$i.txt)
            printf ",download%d,%s" "$i" "$time" >> ./report/benchmark.csv
          done
          for i in $(seq 1 $quantity); do
            update_time=$(measure_time rclone copy ./report/arquivo_$i.txt $profile:$bucket_name-$client)
            printf ",update%d,%s,%s" "$i" "$time" >> ./report/benchmark.csv
          done
          for i in $(seq 1 $quantity); do
            delete_time=$(measure_time rclone delete $profile:$bucket_name-$client/arquivo_$i.txt)
            printf ",delete%d,%s" "$i" "$time" >> ./report/benchmark.csv
          done
          ;;
        "mgc")
          mgc profile set "$profile" > /dev/null
          for i in $(seq 1 $quantity); do
            create_time=$(measure_time mgc object-storage objects upload ./report/arquivo_$i.txt $bucket_name-$client)
            printf ",create%d,%s" "$i" "$time" >> ./report/benchmark.csv
          done
          for i in $(seq 1 $quantity); do
            download_time=$(measure_time mgc object-storage objects download $bucket_name-$client/arquivo_$i.txt ./$bucket_name-$client/arquivo_$i.txt)
            printf ",download%d,%s" "$i" "$time" >> ./report/benchmark.csv
          done
          for i in $(seq 1 $quantity); do
            update_time=$(measure_time mgc object-storage objects upload ./report/arquivo_$i.txt $bucket_name-$client)
            printf ",update%d,%s,%s" "$i" "$time" >> ./report/benchmark.csv
          done
          for i in $(seq 1 $quantity); do
            delete_time=$(measure_time mgc object-storage objects delete $bucket_name-$client/arquivo_$i.txt --no-confirm)
            printf ",delete%d,%s" "$i" "$time" >> ./report/benchmark.csv
          done
          ;;
      esac
    done
    rclone purge $profile:$bucket_name-$client > /dev/null
  End
End