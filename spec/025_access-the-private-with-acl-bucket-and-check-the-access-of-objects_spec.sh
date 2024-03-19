

Describe 'Access the Private with ACL bucket and check the access of objects:' category:"Bucket Permission"
  setup(){
    bucket_name="test-025-$(date +%s)"
    file1_name="LICENSE"
    id="fake-user"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"025"
    profile=$1
    client=$2
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    aws --profile $profile s3 mb s3://$bucket_name-$client
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-read id=$id --grant-write id=$id
    When run aws --profile $profile-second s3api get-object --bucket $bucket_name-$client --key $file1_name $file1_name-2
    The status should be failure
    The stderr should include "An error occurred (403) when calling the GetObject operation: Forbidden"
    aws s3 rb s3://$bucket_name-$client --profile $profile --force
      ;;
    "rclone")
    aws --profile $profile s3 mb s3://$bucket_name-$client
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-read id=$id --grant-write id=$id
    When run rclone copy $profile-second:$bucket_name-$client/$file1_name $file1_name-2
    The status should be failure
    The stderr should include ERROR
    aws s3 rb s3://$bucket_name-$client --profile $profile --force
      ;;
    "mgc")
      Skip 'Teste pulado para cliente mgc'
      # mgc object-storage buckets create $bucket_name-$client
      # mgc object-storage buckets acl set --grant-read id=$id --bucket $bucket_name-$client
      # mgc object-storage objects upload --src $file1_name --dst $bucket_name-$client
      # When run mgc object-storage objects download --src $bucket_name-$client/$file1_name .
      # The status should be failure
      # The output should include "403"
      # mgc object-storage buckets delete $bucket_name-$client -f --force
      ;;
    esac
  End
End
