Describe 'Set a presigned URL for a private bucket:' category:"Bucket Sharing"
  setup(){
    bucket_name="test-035-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"035"
    profile=$1
    client=$2
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    When run aws --profile $profile s3 presign s3://$bucket_name-$client/$file1_name
    The status should be success
    The output should include X-Amz-Algorithm
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
    mgc workspace set $profile > /dev/null
      When run bash ./spec/retry_command.sh "mgc object-storage objects presign --dst $bucket_name-$client/$file1_name --expires-in "5m" --raw"
    # When run mgc object-storage objects presign --dst $bucket_name-$client/$file1_name --expires-in "5m" --raw
    The status should be success
    The output should include X-Amz-Algorithm
      ;;
    esac
    rclone purge --log-file /dev/null "$profile:$bucket_name-$client" > /dev/null
  End
End
