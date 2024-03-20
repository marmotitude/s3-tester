Describe 'Set the versioning for a bucket with ACL:' category:"Object Versioning"
  setup(){
    bucket_name="test-041-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"041"
    profile=$1
    client=$2
    id="fake-user"
    aws --profile $profile s3 mb s3://$bucket_name-$client
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-write id=$id --grant-read id=$id
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    When run aws s3api --profile $profile put-bucket-versioning --bucket $bucket_name-$client --versioning-configuration Status=Enabled
    The output should include ""
      ;;
    "rclone")
      Skip 'Teste pulado para cliente rclone'
      ;;
    "mgc")
      When run mgc object-storage buckets versioning enable $bucket_name-$client
      The output should include ""
      ;;
    esac
    The status should be success
    aws --profile $profile s3 rb s3://$bucket_name-$client --force
  End
End
