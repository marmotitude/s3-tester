# import functions: get_test_bucket_name, create_test_bucket, remove_test_bucket
Include ./spec/053_utils.sh
# import function create_file
Include ./spec/054_utils.sh

# constants
% UNIQUE_SUFIX: $(date +%s)

setup(){
  for profile in $PROFILES; do
    create_test_bucket $profile
  done
  BUCKET_NAME=$(get_test_bucket_name)
  create_file 5 mb
}
setup

Describe 'Upload Files' category:"Object Management" id:"055"
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1, using client $2, upload $local_file to bucket $BUCKET_NAME"
    profile=$1
    client=$2
    key="test-053-file-$(date +%s)"

    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile $profile s3api put-object --bucket $BUCKET_NAME --body $local_file --key $key
      The status should be success
      The output should include "ETag"
      ;;
    "aws-s3")
      When run aws --profile $profile s3 cp $local_file "s3://$BUCKET_NAME/$key"
      The status should be success
      The output should include "upload: "
      The output should include "$local_file to s3://$BUCKET_NAME/$key"
      ;;
    "rclone")
      When run rclone copyto $local_file $profile:$BUCKET_NAME/$key --no-check-dest -v
      The status should be success
      The error should include " Copied"
      The error should include "to: $key"
      ;;
    esac
  End
End
