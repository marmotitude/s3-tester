Describe 'Access the Private with ACL bucket and check the access of objects:' category:"Bucket Permission"
  setup(){
    bucket_name="test-029-$(date +%s)"
    file1_name="LICENSE"
    id="fake-user"
    id2="fake-user"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"029"
    profile=$1
    client=$2
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    aws --profile $profile s3 mb s3://$bucket_name-$client
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-read id=$id
    When run aws --profile $profile-second s3api get-object --bucket $bucket_name-$client --key $file1_name $file1_name-2
    The status should be failure
    The stderr should include "An error occurred (403) when calling the GetObject operation: Forbidden"
    aws s3 rb s3://$bucket_name-$client --profile $profile --force
      ;;
    "rclone")
    aws --profile $profile s3 mb s3://$bucket_name-$client
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-read id=$id
    When run rclone copy $profile-second:$bucket_name-$client/$file1_name $file1_name-2
    The status should be failure
    The stderr should include "ERROR"
    aws s3 rb s3://$bucket_name-$client --profile $profile --force
      ;;
    esac
  End
End
