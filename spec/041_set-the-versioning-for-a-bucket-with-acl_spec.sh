is_variable_null() {
  [ -z "$1" ]
}

Describe 'Set the versioning for a bucket with ACL:' category:"Object Versioning"
  setup(){
    bucket_name="test-041-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"041"
    profile=$1
    client=$2
    id=$(aws s3api --profile $profile-second list-buckets | jq -r '.Owner.ID')
    Skip if "No such a "$profile-second" user" is_variable_null "$id"
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-write id=$id --grant-read id=$id > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    When run aws s3api --profile $profile put-bucket-versioning --bucket $bucket_name-$client --versioning-configuration Status=Enabled
    The output should include ""
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
    mgc profile set $profile > /dev/null
    When run mgc object-storage buckets versioning enable $bucket_name-$client --raw
    The output should include "Enabled versioning for $bucket_name-$client"
      ;;
    esac
    The status should be success
    aws --profile $profile s3 rb s3://$bucket_name-$client --force > /dev/null
  End
End
