Describe 'Access the private bucket and check the list of objects:' category:"Bucket Permission"
  setup(){
    bucket_name="test-022-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"022"
    profile=$1
    client=$2
    case "$client" in
    "aws-s3api" | "aws")
    aws --profile $profile s3 mb s3://$bucket_name
    aws --profile $profile s3 cp $file1_name s3://$bucket_name
    When run aws --profile $profile-second s3api list-objects-v2 --bucket $bucket_name
    The status should be failure
    The stderr should include "An error occurred (403) when calling the ListObjectsV2 operation: Forbidden"
    aws s3 rb s3://$bucket_name --profile $profile --force
    ;;
    "aws-s3")
    aws --profile $profile s3 mb s3://$bucket_name
    aws --profile $profile s3 cp $file1_name s3://$bucket_name
    When run aws --profile $profile-second s3api list-objects-v2 --bucket $bucket_name
    The status should be failure
    The stderr should include "An error occurred (403) when calling the ListObjectsV2 operation: Forbidden"
    aws s3 rb s3://$bucket_name --profile $profile --force
    ;;
    "rclone")
    aws --profile $profile s3 mb s3://$bucket_name
    aws --profile $profile s3 cp $file1_name s3://$bucket_name
    When run rclone ls $profile-second:$bucket_name
    The status should be failure
    The stderr should include "403"
    aws s3 rb s3://$bucket_name --profile $profile --force
    ;;
    esac
  End
End
