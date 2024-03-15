Describe 'Create bucket' category:"Bucket Management" id:"001"
  setup(){
    bucket_name="test-001-$(date +%s)"
  }
  teardown(){
    aws --profile $profile s3api delete-bucket --bucket $bucket_name
  }
  Before setup
  After teardown
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "with unique name on profile $1 using client $2"
    profile=$1
    client=$2
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile $profile s3api create-bucket --bucket $bucket_name
      The status should be success
      The output should include "\"Location\": \"/$bucket_name\""
      ;;
    "aws-s3")
      When run aws --profile $profile s3 mb s3://$bucket_name
      The status should be success
      The output should include "make_bucket: $bucket_name"
      ;;
    "rclone")
      When run rclone mkdir $profile:$bucket_name -v
      The status should be success
      The error should include "Bucket \"$bucket_name\" created"
      ;;
    esac
  End
End
