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
    case "$client" in
    "aws-s3api" | "aws")
    aws --profile $profile s3 mb s3://$bucket_name-$client
    When run aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-read id=$id
    The status should be success
    The output should include ""
    aws s3 rb s3://$bucket_name-$client --profile $profile
      ;;
    "aws-s3")
    aws --profile $profile s3 mb s3://$bucket_name-$client
    When run aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-read id=$id
    The status should be success
    The output should include ""
    aws s3 rb s3://$bucket_name-$client --profile $profile
      ;;
    "rclone")
    aws --profile $profile s3 mb s3://$bucket_name-$client
    When run aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-read id=$id
    The status should be success
    The output should include ""
    aws s3 rb s3://$bucket_name-$client --profile $profile
      ;;
    esac
  End
End
