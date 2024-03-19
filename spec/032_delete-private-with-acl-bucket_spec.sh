Describe 'Delete private with ACL bucket:' category:"Bucket Permission"
  setup(){
    bucket_name="test-032-$(date +%s)"
    file1_name="LICENSE"
    "fake-user"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"032"
    profile=$1
    client=$2
    aws --profile $profile s3 mb s3://$bucket_name-$client
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-read id=$id
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
    When run rclone delete $profile:$bucket_name-$client
    The output should include ""
      ;;
    "mgc")
      When run mgc object-storage buckets delete $bucket_name-$client -f
      The output should include ""
      ;;
    esac
    The status should be success
  End
End
