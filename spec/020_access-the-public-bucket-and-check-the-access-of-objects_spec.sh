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
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client --acl public-read  > /dev/null
    aws --profile $profile s3api wait bucket-exists --bucket $bucket_name-$client
    aws --profile $profile-second s3api wait bucket-exists --bucket $bucket_name-$client
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3api wait object-exists --key $file1_name --bucket $bucket_name-$client
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    When run aws --profile $profile-second s3api get-object --bucket $bucket_name-$client --key $file1_name $file1_name-2
    The stderr should include "AccessDenied"
    The status should be failure
    ;;
    "rclone")
    When run rclone copy $profile-second:$bucket_name-$client/$file1_name $file1_name-2 -v
    The stderr should include "There was nothing to transfer"
    ;;
    "mgc")
      mgc profile set $profile-second > /dev/null
      When run bash ./spec/retry_command.sh "mgc object-storage objects download --src $bucket_name-$client/$file1_name --dst . --raw"
      #When run mgc object-storage objects download --src $bucket_name-$client/$file1_name --dst . --raw
      The status should be failure
      The output should include "403 Forbidden"
      #The stderr should include "403 Forbidden"
      ;;
    esac
    rclone purge --log-file /dev/null "$profile:$bucket_name-$client" > /dev/null
    bash ./spec/retry_command.sh  "aws s3api wait bucket-not-exists --bucket $bucket_name-$client --profile $profile"
  End
End

