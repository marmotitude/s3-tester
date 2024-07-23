Include ./spec/019_utils.sh
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
    wait_command bucket-exists $profile "$bucket_name-$client"
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    When run aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-write id=$id --grant-read id=$id
    The output should include ""
      ;;
    "rclone")
    Skip "Skipped test to $client"
      ;;
    "mgc")
      mgc profile set $profile > /dev/null
      #Skip "Skipped test to $client"
      When run mgc object-storage buckets acl set --grant-read id=$id --grant-write id=$id --dst $bucket_name-$client --raw
      The output should include ""
      ;;
    esac
    rclone purge --log-file /dev/null "$profile:$bucket_name-$client" > /dev/null
    wait_command bucket-not-exists $profile "$bucket_name-$client"
    The status should be success
  End
End

Describe 'Validate a ACL write for a bucket:' category:"Bucket Permission"
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
    wait_command bucket-exists $profile "$bucket_name-$client"
    aws --profile $profile s3api put-bucket-acl --bucket $bucket_name-$client --grant-write id=$id
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    When run aws --profile $profile-second s3 cp $file1_name s3://$bucket_name-$client
    The output should include "upload: ./$file1_name to s3://$bucket_name-$client/$file1_name"
      ;;
    "rclone")
    Skip "Skipped test to $client"
      ;;
    "mgc")
      mgc profile set $profile > /dev/null
      #Skip "Skipped test to $client"
      mgc object-storage buckets acl set --grant-write id=$id --dst $bucket_name-$client
      mgc profile set $profile-second > /dev/null
      When run mgc object-storage objects upload $file1_name --dst $bucket_name-$client --raw
      The output should include "Uploaded file $file1_name to $bucket_name-$client/$file1_name"
      ;;
    esac
    rclone purge --log-file /dev/null "$profile:$bucket_name-$client" > /dev/null
    wait_command bucket-not-exists $profile "$bucket_name-$client"
    The status should be success
  End
End
