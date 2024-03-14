Describe 'Create private bucket:' category:"Bucket Permission"
  setup(){
    bucket_name="test-020-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup' 
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"021"
    profile=$1
    client=$2
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile $profile s3api create-bucket --bucket $bucket_name
      The status should be success
      The output should include "\"Location\": \"/$bucket_name\""
      aws s3 rb s3://$bucket_name --profile $profile --force
      ;;
    "aws-s3")
      When run aws --profile $profile s3 mb s3://$bucket_name
      The status should be success
      The output should include "make_bucket: $bucket_name"
      aws s3 rb s3://$bucket_name --profile $profile --force
      ;;
    "rclone")
      When run rclone mkdir $profile:$bucket_name --s3-acl=public-read -v
      The status should be success
      The error should include "Bucket \"$bucket_name\" created"
      aws s3 rb s3://$bucket_name --profile $profile --force
      ;;
    esac
  End
End
