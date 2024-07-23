# import functions: wait_command
Include ./spec/019_utils.sh
is_variable_null() {
  [ -z "$1" ]
}

Describe 'Unique bucket:' category:"Bucket Management"
  setup(){
    bucket_name="test-090-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"090"
    profile=$1
    client=$2
    id=$(aws s3api --profile $profile-second list-buckets | jq -r '.Owner.ID')
    Skip if "No such a "$profile-second" user" is_variable_null "$id"
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    wait_command bucket-exists $profile "$bucket_name-$client"
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile $profile s3api create-bucket --bucket $bucket_name-$client
      The error should include "BucketAlreadyExists"
      The status should be failure
      ;;
    "aws-s3")
      When run aws --profile $profile s3 mb s3://$bucket_name-$client
      The error should include "BucketAlreadyExists"
      The status should be failure
      ;;
    "rclone")
      When run rclone mkdir $profile:$bucket_name-$client -vv --dump-headers
      The error should include "409 Conflict"
      The status should be success
      ;;
    "mgc")
      mgc profile set $profile > /dev/null
      When run mgc object-storage buckets create $bucket_name-$client --raw
      The error should include "BucketAlreadyExists"
      The status should be failure
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    aws s3 rb s3://$bucket_name-$client --profile $profile --force > /dev/null
    wait_command bucket-not-exists "$profile" "$bucket_name-$client"
  End
End
