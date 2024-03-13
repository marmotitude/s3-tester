Include ./spec/053_utils.sh
BeforeAll 'setup'
AfterAll 'teardown'
Describe 'Upload Files' category:"Object Management" id:"053"
  Parameters:matrix
    $PROFILES
    $CLIENTS
    LICENSE README.md main.Dockerfile
  End
  After 'delete_file'
  Example "on profile $1, using client $2, upload local file $3 to bucket $BUCKET_NAME"
    profile=$1
    client=$2
    local_file=$3
    key="test-053-file-$(date +%s)"
    BUCKET_NAME=$(get_bucket_name)

    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile $profile s3api put-object --bucket $BUCKET_NAME --body $local_file --key $key
      The status should be success
      The output should include "ETag"
      ;;
    "aws-s3")
      When run aws --profile $profile s3 cp $local_file "s3://$BUCKET_NAME/$key"
      The status should be success
      The output should include "upload: ./$local_file to s3://$BUCKET_NAME/$key"
      ;;
    "rclone")
      When run rclone copyto $local_file $profile:$BUCKET_NAME/$key -v
      The status should be success
      The error should include "$local_file: Copied"
      The error should include "to: $key"
      ;;
    esac
  End
End

