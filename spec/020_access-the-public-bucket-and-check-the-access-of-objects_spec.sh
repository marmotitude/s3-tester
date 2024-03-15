Describe 'Access the public bucket and check the access of objects:' category:"Bucket Permission"
  setup(){
    bucket_name="test-020-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"020"
    profile=$1
    client=$2
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client --acl public-read | jq
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client
    When run aws --profile $profile-second s3api get-object --bucket $bucket_name-$client --key $file1_name $file1_name-2
    The status should be failure
    The stderr should include "An error occurred (403) when calling the GetObject operation: Forbidden"
    aws s3 rb s3://$bucket_name-$client --profile $profile --force
    ;;
    "rclone")
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client --acl public-read | jq
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client
    When run rclone copy $profile-second:$bucket_name-$client/$file1_name $file1_name-2
    The status should be failure
    The stderr should include "ERROR"
    aws s3 rb s3://$bucket_name-$client --profile $profile --force
    ;;
    esac
  End
End

