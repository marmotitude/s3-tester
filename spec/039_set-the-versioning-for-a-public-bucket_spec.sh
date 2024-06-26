Describe 'Set the versioning for a public bucket:' category:"Object Versioning"
  setup(){
    bucket_name="test-039-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"039"
    profile=$1
    client=$2
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client --acl public-read  > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    When run aws s3api --profile $profile put-bucket-versioning --bucket $bucket_name-$client --versioning-configuration Status=Enabled
    The output should include ""
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
    mgc profile set-current $profile > /dev/null
    When run mgc object-storage buckets versioning enable $bucket_name-$client
    The output should include "Enabled versioning for $bucket_name-$client"
      ;;
    esac
    The status should be success
    aws --profile $profile s3 rb s3://$bucket_name-$client --force > /dev/null
  End
End
