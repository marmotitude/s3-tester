Describe 'Create ACL in a batch for more than 2 ppl with option of R and R/W differents:' category:"Bucket Permission"
  setup(){
    bucket_name="test-027-$(date +%s)"
    file1_name="LICENSE"
    id="fake-user"
    id2="fake-user"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"027"
    profile=$1
    client=$2
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    aws --profile $profile s3 mb s3://$bucket_name-$client
    When run aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-write id=$id --grant-read id=$id2
    The status should be success
    The output should include ""
    aws s3 rb s3://$bucket_name-$client --profile $profile --force
      ;;
    "rclone")
    Skip 'Teste pulado para cliente rclone'
      ;;
    "mgc")
      mgc object-storage buckets create $bucket_name-$client
      When run mgc object-storage buckets acl set --grant-read id=$id --grant-write id=$id --bucket $bucket_name-$client
      The status should be success
      The output should include ""
      mgc object-storage buckets delete $bucket_name-$client -f --force
      ;;
    esac
  End
End
