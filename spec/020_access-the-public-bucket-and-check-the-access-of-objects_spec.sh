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
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client --acl public-read | jq
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    When run aws --profile $profile-second s3api get-object --bucket $bucket_name-$client --key $file1_name $file1_name-2
    The status should be failure
    The stderr should include "An error occurred (403) when calling the GetObject operation: Forbidden"
    aws s3 rb s3://$bucket_name-$client --profile $profile --force
    ;;
    "rclone")
    When run rclone copy $profile-second:$bucket_name-$client/$file1_name $file1_name-2
    The status should be failure
    The stderr should include "ERROR"
    aws s3 rb s3://$bucket_name-$client --profile $profile --force
    ;;
    "mgc")
      Skip 'Teste pulado para cliente mgc'
      # When run mgc object-storage objects download --src $bucket_name-$client/$file1_name --dst .
      # The status should be failure
      # The output should include "403"
      # mgc object-storage buckets delete $bucket_name-$client -f --force
      ;;
    esac
  End
End

