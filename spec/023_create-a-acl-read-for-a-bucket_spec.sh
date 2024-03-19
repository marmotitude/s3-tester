Describe 'Create a ACL read for a bucket:' category:"Bucket Permission"
  setup(){
    bucket_name="test-023-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"023"
    profile=$1
    client=$2
    id="fake-user"
    aws --profile $profile s3 mb s3://$bucket_name-$client
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-read id=$id
      The output should include ""
      ;;
    "rclone")
      Skip 'Teste pulado para cliente rclone'
      ;;
    "mgc")
      When run mgc object-storage buckets acl set --grant-read id=$id --bucket $bucket_name-$client
      The output should include ""
      ;;
    esac
    The status should be success
    aws s3 rb s3://$bucket_name-$client --profile $profile
  End
End
