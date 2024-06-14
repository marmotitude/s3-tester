Include ./spec/019_utils.sh

Describe 'Create public bucket:' category:"Bucket Permission"
  setup(){
    bucket_name="test-018-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"018"
    profile=$1
    client=$2
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile s3api create-bucket --bucket $bucket_name-$client --acl public-read
      The output should include "\"Location\": \"/$bucket_name-$client\""
      ;;
    "rclone")
      When run rclone mkdir $profile:$bucket_name-$client --s3-acl=public-read -v
      The status should be success
      The error should include "Bucket \"$bucket_name-$client\" created"
      ;;
    "mgc")
      mgc profile set-current $profile > /dev/null
      When run mgc object-storage buckets create $bucket_name-$client --public-read
      The output should include "Created bucket $bucket_name-$client"
      ;;
    esac
    The status should be success
    aws --profile $profile s3api wait bucket-exists --bucket $bucket_name-$client
    rclone purge --log-file /dev/null "$profile:$bucket_name-$client" > /dev/null
    wait_command bucket-not-exists $profile "$bucket_name-$client"
  End
End
