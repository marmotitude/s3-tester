is_variable_null() {
  [ -z "$1" ]
}

Describe 'Validate the URL of presigned for the ACL bucket:' category:"Bucket Sharing"
  setup(){
    bucket_name="test-038-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"038"
    profile=$1
    client=$2
    id=$(aws s3api --profile $profile-second list-buckets | jq -r '.Owner.ID')
    Skip if "No such a "$profile-second" user" is_variable_null "$id"
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client > /dev/null
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-write id=$id --grant-read id=$id > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    presign_url=$(aws --profile $profile s3 presign s3://$bucket_name-$client/$file1_name)
    When run curl $presign_url
    The status should be success
    The output should include Copyright
    The error should include Current
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
    mgc profile set $profile > /dev/null
    presign_url=$(mgc object-storage objects presign --dst $bucket_name-$client/$file1_name --expires-in "5m")
    When run curl $presign_url
    The output should include Copyright
    The error should include Current
      ;;
    esac
    aws --profile $profile s3 rb s3://$bucket_name-$client --force > /dev/null
  End
End
