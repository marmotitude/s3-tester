is_variable_null() {
  [ -z "$1" ]
}

Describe 'Access the Private with ACL bucket with and check the list of objects:' category:"Bucket Permission"
  setup(){
    bucket_name="test-024-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"024"
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
    When run aws --profile $profile-second s3api list-objects-v2 --bucket $bucket_name-$client
    The output should include "$file1_name"
      ;;
    "rclone")
    When run rclone ls $profile-second:$bucket_name-$client
    The output should include "$file1_name"
      ;;
    "mgc")
      mgc profile set-current $profile-second > /dev/null
      #Skip "Skipped test to $client"
      When run mgc object-storage objects list --dst $bucket_name-$client --raw
      The output should include $file1_name
      ;;
    esac
    The status should be success
    aws s3 rb s3://$bucket_name-$client --profile $profile --force > /dev/null
    aws s3api wait bucket-not-exists --bucket $bucket_name-$client --profile $profile
  End
End
