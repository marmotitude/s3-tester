is_variable_null() {
  [ -z "$1" ]
}

Describe 'Create a ACL read/write for a bucket:' category:"Bucket Permission"
  setup(){
    bucket_name="test-026-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"026"
    profile=$1
    client=$2
    id=$(aws s3api --profile $profile-second list-buckets | jq -r '.Owner.ID')
    Skip if "No such a "$profile-second" user" is_variable_null "$id"
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3api wait bucket-exists --bucket $bucket_name-$client
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    When run aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-write id=$id --grant-read id=$id
    The output should include ""
      ;;
    "rclone")
    Skip "Skipped test to $client"
      ;;
    "mgc")
      mgc profile set-current $profile > /dev/null
      #Skip "Skipped test to $client"
      When run mgc object-storage buckets acl set --grant-read id=$id --grant-write id=$id --dst $bucket_name-$client
      The output should include ""
      ;;
    esac
    aws s3 rb s3://$bucket_name-$client --profile $profile --force > /dev/null
    aws s3api wait bucket-not-exists --bucket $bucket_name-$client --profile $profile
    The status should be success
  End
End
