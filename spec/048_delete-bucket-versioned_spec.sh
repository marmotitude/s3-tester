Describe 'Delete Bucket versioned:' category:"Object Versioning"
  setup(){
    bucket_name="test-048-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"048"
    profile=$1
    client=$2  
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client > /dev/null
    aws s3api --profile $profile put-bucket-versioning --bucket $bucket_name-$client --versioning-configuration Status=Enabled > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    When run aws --profile $profile s3 rb s3://$bucket_name-$client --force
    The output should include ""
      ;;
    "rclone")
    When run rclone rmdir $profile:$bucket_name-$client
    The output should include ""
      ;;
    "mgc")
    mgc profile set-current $profile > /dev/null
    When run mgc object-storage buckets delete $bucket_name-$client -f
    The output should include ""
      ;;
    esac
    The status should be success
  End
End