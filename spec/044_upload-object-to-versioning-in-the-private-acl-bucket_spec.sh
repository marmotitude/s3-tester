is_variable_null() {
  [ -z "$1" ]
}

Describe 'Upload object to versioning in the private acl bucket:' category:"Object Versioning"
  setup(){
    bucket_name="test-044-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"044"
    profile=$1
    client=$2
    id=$(aws s3api --profile $profile-second list-buckets | jq -r '.Owner.ID')
    Skip if "No such a "$profile-second" user" is_variable_null "$id"
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-write id=$id --grant-read id=$id > /dev/null
    aws s3api --profile $profile put-bucket-versioning --bucket $bucket_name-$client --versioning-configuration Status=Enabled > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    When run aws --profile $profile-second s3 cp $file1_name s3://$bucket_name-$client
    The output should include "$file1_name"
      ;;
    "rclone")
    When run rclone copy $file1_name $profile-second:$bucket_name-$client
    The output should include ""
      ;;
    "mgc")
    mgc profile set $profile-second > /dev/null
    When run bash ./spec/retry_command.sh "mgc object-storage objects upload --src $file1_name --dst $bucket_name-$client --raw"
    # When run mgc object-storage objects upload --src $file1_name --dst $bucket_name-$client --raw
    The output should include ""
      ;;
    esac
    The status should be success
    rclone purge --log-file /dev/null "$profile:$bucket_name-$client" > /dev/null
  End
End
