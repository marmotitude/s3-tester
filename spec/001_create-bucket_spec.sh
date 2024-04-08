# constants
% UNIQUE_SUFIX: $(date +%s)

get_test_bucket_name(){
  echo "test-001-$profile-$client-$UNIQUE_SUFIX"
}
#001 is also used as setup for 015
Describe 'Create bucket' category:"Bucket Management" id:"001" id"015"
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "with unique name on profile $1 using client $2"
    profile=$1
    client=$2
    bucket_name=$(get_test_bucket_name)
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile "$profile" s3api create-bucket --bucket "$bucket_name"
      The status should be success
      The output should include "\"Location\": \"/$bucket_name\""
      ;;
    "aws-s3")
      When run aws --profile "$profile" s3 mb "s3://$bucket_name"
      The status should be success
      The output should include "make_bucket: $bucket_name"
      ;;
    "rclone")
      When run rclone mkdir "$profile:$bucket_name" -v
      The status should be success
      The error should include "Bucket \"$bucket_name\" created"
      ;;
    "mgc")
      mgc profile set-current $profile > /dev/null
      When run mgc object-storage buckets create "$bucket_name"
      The status should be success
      The output should include "Created bucket $bucket_name"
      ;;
    esac
  End
End

#015 is also used as teardown of 001
Describe 'Delete Buckets empty' category:"Bucket Management" id:"001" id:"015" 
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "for profile $1 using client $2"
    profile=$1
    client=$2
    bucket_name=$(get_test_bucket_name)
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile "$profile" s3api delete-bucket --bucket "$bucket_name"
      The status should be success
      ;;
    "aws-s3")
      When run aws --profile "$profile" s3 rb "s3://$bucket_name"
      The status should be success
      The output should include "remove_bucket: $bucket_name"
      ;;
    "rclone")
      When run rclone rmdir "$profile:$bucket_name" -v
      The status should be success
      The error should include "S3 bucket $bucket_name: Bucket \"$bucket_name\" deleted"
      ;;
    "mgc")
      mgc profile set-current $profile > /dev/null
      When run mgc object-storage buckets delete "$bucket_name" -f
      The status should be success
      ;;
    esac
  End
End
