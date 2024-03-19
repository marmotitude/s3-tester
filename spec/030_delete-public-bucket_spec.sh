Describe 'Delete public bucket:' category:"Bucket Permission"
  setup(){
    bucket_name="test-030-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"030"
    profile=$1
    client=$2
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client --acl public-read | jq
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    When run aws --profile $profile s3 rb s3://$bucket_name-$client --force
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
