Describe 'Delete private with ACL bucket:' category:"Bucket Permission"
  setup(){
    bucket_name="test-032-$(date +%s)"
    file1_name="LICENSE"
    id="fake-user"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"032"
    profile=$1
    client=$2
    case "$client" in
    "aws" | "aws-s3")
    aws --profile $profile s3 mb s3://$bucket_name-$client
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-read id=$id
    When run aws --profile $profile s3 rb s3://$bucket_name-$client --force
    The status should be success
    The output should include "$bucket_name-$client"
      ;;
    "aws-s3api")
    aws --profile $profile s3 mb s3://$bucket_name-$client
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-read id=$id
    When run aws --profile $profile s3api delete-bucket --bucket $bucket_name-$client
    The status should be success
    The output should include "$bucket_name-$client"
      ;;
    "rclone")
    aws --profile $profile s3 mb s3://$bucket_name-$client
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-read id=$id
    When run rclone delete $profile:$bucket_name-$client
    The status should be success
    The output should include ""
      ;;
    esac
  End
End
