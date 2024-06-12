wait_command() {
  profile_to_wait=$1
  bucket_name_to_wait=$2
  number_of_waits=$3
  command=$4

  # aws s3api wait does not allow a custom timeout, so we repeat several waits if we need more than
  # the default of 20 attempts, or 100 seconds
  for ((i=1; i<=number_of_waits; i++))
  do
    echo "wait $command for profile $profile_to_wait attempt number: $i, $(date)"
    aws --profile $profile_to_wait s3api wait $command --bucket $bucket_name_to_wait 2>&1 || echo falhou $i
  done
  echo ".last wait $command for profile $profile_to_wait, $(date)"
  aws --profile $profile_to_wait s3api wait $command --bucket $bucket_name_to_wait
}

Describe 'Access the public bucket and check the list of objects:' category:"Bucket Permission"
  setup(){
    bucket_name="test-019-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup' 
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"019"
    profile=$1
    client=$2
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client --acl public-read > /dev/null
    wait_command $profile "$bucket_name-$client" $NUMBER_OF_WAITS bucket-exists
    #aws --profile $profile s3api wait bucket-exists --bucket $bucket_name-$client
    wait_command "$profile-second" "$bucket_name-$client" $NUMBER_OF_WAITS bucket-exists
    #aws --profile $profile-second s3api wait bucket-exists --bucket $bucket_name-$client
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3api wait object-exists --bucket $bucket_name-$client --key $file1_name
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile-second s3api list-objects-v2 --bucket $bucket_name-$client
      The output should include "$file1_name"
      ;;
    "rclone")
      When run rclone ls $profile-second:$bucket_name-$client
      The output should include "$file1_name"
      ;;
    "mgc")
      mgc profile set-current $profile-second > /dev/null
      When run mgc object-storage objects list --dst $bucket_name-$client
      The output should include "$file1_name"
      ;;
    esac
    The status should be success
    rclone purge --log-file /dev/null "$profile:$bucket_name-$client" > /dev/null
    wait_command $profile "$bucket_name-$client" $NUMBER_OF_WAITS bucket-not-exists
  End
End
