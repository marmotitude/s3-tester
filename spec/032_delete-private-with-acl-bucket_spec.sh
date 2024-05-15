is_variable_null() {
  [ -z "$1" ]
}

Describe 'Delete private with ACL bucket:' category:"Bucket Permission"
  setup(){
    bucket_name="test-032-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"032"
    profile=$1
    client=$2
    id=$(aws s3api --profile $profile-second list-buckets | jq -r '.Owner.ID')
    Skip if "No such a "$profile-second" user" is_variable_null "$id"
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-read id=$id > /dev/null
    case "$client" in
    "aws" | "aws-s3")
    When run aws --profile $profile s3 rb s3://$bucket_name-$client --force
    The output should include "$bucket_name-$client"
      ;;
    "aws-s3api")
    When run aws --profile $profile s3api delete-bucket --bucket $bucket_name-$client
    The output should include "$bucket_name-$client"
      ;;
    "rclone")
    When run rclone rmdir $profile:$bucket_name-$client
    The output should include ""
      ;;
    "mgc")
      mgc profile set-current $profile > /dev/null
      When run mgc object-storage buckets delete $bucket_name-$client --no-confirm
      The output should include ""
      ;;
    esac
    The status should be success
  End
End
