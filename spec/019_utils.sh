wait_command() {
  command=$1
  profile_to_wait=$2
  bucket_name_to_wait=$3
  object_name_to_wait=$4
  key_argument=$([ -z "$4" ] && echo "" || echo "--key $4")
  number_of_waits=$NUMBER_OF_WAITS

  # aws s3api wait does not allow a custom timeout, so we repeat several waits if we need more than
  # the default of 20 attempts, or 100 seconds
  for ((i=1; i<=number_of_waits; i++))
  do
    echo "wait $command for profile $profile_to_wait attempt number: $i, $(date)"
    aws --profile $profile_to_wait s3api wait $command --bucket $bucket_name_to_wait $key_argument 2>&1 || echo falhou $i
  done
  echo "last wait $command for profile $profile_to_wait, $(date)"
  aws --profile $profile_to_wait s3api wait $command --bucket $bucket_name_to_wait $key_argument
}


