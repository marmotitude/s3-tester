Describe 'get-presign:' category:"Bucket Sharing"
  setup(){
    bucket_name="test-036-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"036"
    profile=$1
    client=$2
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    presign_url=$(aws --profile $profile s3 presign s3://$bucket_name-$client/$file1_name)
    When run curl $presign_url
    The output should include Copyright
    The error should include Current
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
    mgc workspace set $profile > /dev/null
    presign_url=$(mgc object-storage objects presign --dst $bucket_name-$client/$file1_name --expires-in "5m")
    When run curl $presign_url
    The output should include Copyright
    The error should include Current
      ;;
    esac
    The status should be success
    rclone purge --log-file /dev/null "$profile:$bucket_name-$client" > /dev/null
  End
End

Describe 'put-presign:' category:"Bucket Sharing"
  setup(){
    bucket_name="test-036-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"036"
    profile=$1
    client=$2
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      Skip "Skipped test to $client"
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
    mgc workspace set $profile > /dev/null
    presign_url=$(mgc object-storage objects presign --dst $bucket_name-$client/$file1_name --expires-in "5m" --method PUT)
    When run curl -X PUT -T $file1_name $presign_url
    The error should include Current
      ;;
    esac
    The status should be success
    rclone purge --log-file /dev/null "$profile:$bucket_name-$client" > /dev/null
  End
End
