Describe 'Create public bucket:' category:"Bucket Permission"
  setup(){
    bucket_name="test-018-$(date +%s)"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"018"
    profile=$1
    client=$2
    file1_name="file1.txt"
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile s3api create-bucket --bucket $bucket_name-$client --acl public-read
      The status should be success
      The output should include "\"Location\": \"/$bucket_name-$client\""
      aws s3 rb s3://$bucket_name-$client --profile $profile --force
      ;;
    "rclone")
      When run rclone mkdir $profile:$bucket_name-$client --s3-acl=public-read -v
      The status should be success
      The error should include "Bucket \"$bucket_name-$client\" created"
      aws s3 rb s3://$bucket_name-$client --profile $profile --force
      ;;
    esac
  End
End
