is_variable_null() {
  [ -z "$1" ]
}

Describe 'Access the Private with ACL bucket and check the access of objects:' category:"Bucket Permission"
  setup(){
    bucket_name="test-029-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"029"
    profile=$1
    client=$2
    id=$(aws s3api --profile $profile-second list-buckets | jq -r '.Owner.ID')
    Skip if "No such a "$profile-second" user" is_variable_null "$id"
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3api wait bucket-exists --bucket $bucket_name-$client
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3api wait object-exists --key $file1_name --bucket $bucket_name-$client
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-read id=$id > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    When run aws --profile $profile-second s3api get-object --bucket $bucket_name-$client --key $file1_name $file1_name-2
    The status should be failure
    The stderr should include "An error occurred (AccessDenied) when calling the GetObject operation: Access Denied."
      ;;
    "rclone")
    When run bash ./spec/retry_command.sh "rclone -v copy $profile-second:$bucket_name-$client/$file1_name $file1_name-2"
    # When run rclone -v copy $profile-second:$bucket_name-$client/$file1_name $file1_name-2
    The status should be success
    The stdout should include "There was nothing to transfer"
    # The stderr should include "There was nothing to transfer"
      ;;
    "mgc")
      mgc profile set $profile-second > /dev/null
      When run bash ./spec/retry_command.sh "mgc object-storage objects download --src $bucket_name-$client/$file1_name --dst $file1_name-2 --raw"
      # When run mgc object-storage objects download --src $bucket_name-$client/$file1_name --dst $file1_name-2 --raw
      The status should be failure
      # The stderr should include "403"
      The output should include "403"
      ;;
    esac
    rclone purge --log-file /dev/null "$profile:$bucket_name-$client" > /dev/null
    aws s3api wait bucket-not-exists --bucket $bucket_name-$client --profile $profile
  End
End
