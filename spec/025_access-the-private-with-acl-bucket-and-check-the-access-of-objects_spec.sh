is_variable_null() {
  [ -z "$1" ]
}

Describe 'Access the Private with ACL bucket and check the access of objects:' category:"Bucket Permission"
  setup(){
    bucket_name="test-025-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"025"
    profile=$1
    client=$2    
    id=$(aws s3api --profile $profile-second list-buckets | jq -r '.Owner.ID')
    Skip if "No such a "$profile-second" user" is_variable_null "$id"
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client > /dev/null
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-read id=$id --grant-write id=$id > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    When run aws --profile $profile-second s3api get-object --bucket $bucket_name-$client --key $file1_name $file1_name-2
    The stderr should include "An error occurred (AccessDenied) when calling the GetObject operation: Access Denied."
      ;;
    "rclone")
    When run rclone copy $profile-second:$bucket_name-$client/$file1_name $file1_name-2
    The status should be failure
    The stderr should include ERROR
    # todo: its true if where dont have access the status is success but dont make download? test in other providers
      ;;
    "mgc")
      Skip "Skipped test to $client"
      # mgc object-storage buckets create $bucket_name-$client
      # mgc object-storage buckets acl set --grant-read id=$id --bucket $bucket_name-$client
      # mgc object-storage objects upload --src $file1_name --dst $bucket_name-$client
      # When run mgc object-storage objects download --src $bucket_name-$client/$file1_name .
      # The status should be failure
      # The output should include "403"
      # mgc object-storage buckets delete $bucket_name-$client -f --force
      ;;
    esac
    The status should be failure
    aws s3 rb s3://$bucket_name-$client --profile $profile --force > /dev/null
    Dump
  End
End
