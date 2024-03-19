
Describe 'Delete private bucket:' category:"Bucket Permission"
  setup(){
    bucket_name="test-031-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
 Example "on profile $1 using client $2" id:"031"
    profile=$1
    client=$2
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client| jq
    When run aws --profile $profile s3 rb s3://$bucket_name-$client --force
    The status should be success
    The output should include "$bucket_name-$client"
      ;;
    "rclone")
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client| jq
    When run rclone delete $profile:$bucket_name-$client
    The status should be success
    The output should include ""
      ;;
    "mgc")
      mgc object-storage buckets create $bucket_name-$client
      When run mgc object-storage buckets delete $bucket_name-$client -f
      The status should be success
      The output should include ""
      ;;
    esac
  End
End
