# Upload, List, Download and Delete objects
#
# The test 053 is required for test 057, 061, 062 and 063 so they are linked. Filtering by
# the later will also run the former. 053 is the "setup" for the others.
#
# Tests:
#   - "053 Upload Files"
#   - "057 Download Files"
#   - "061 List Objects"
#   - "062 Delete Objects",
#   - "063 Delete objects in batch"
#
# Env vars:
#   - $TEST_BUCKET_NAME - optional - an existing bucket to be reused
#
#------------------------------------------------------------------------------

# import functions: get_test_bucket_name, get_uploaded_key, create_test_bucket, remove_test_bucket
Include ./spec/053_utils.sh

# constants
% UNIQUE_SUFIX: $(date +%s)
% FILES: "LICENSE README.md main.Dockerfile"

setup(){
  for profile in $PROFILES; do
    create_test_bucket $profile
  done
  BUCKET_NAME=$(get_test_bucket_name)
}
setup

Describe 'Upload Files' category:"Object Management"
  Parameters:matrix
    $PROFILES
    $CLIENTS
    $FILES
  End
  Example "on profile $1, using client $2, upload local file $3 to bucket $BUCKET_NAME" id:"053" id:"057" id:"061" id:"062" id:"063"
    profile=$1
    client=$2
    local_file=$3
    key=$(get_uploaded_key "$local_file")

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
      When run rclone copyto $local_file $profile:$BUCKET_NAME/$key -v --no-check-dest
      The status should be success
      The error should include "$local_file: Copied"
      The error should include "to: $key"
      ;;
    esac
  End
  Describe 'Download Files' category:"Object Management" id:"057"
    Example "from bucket $BUCKET_NAME of profile $1, The file $3, using client $2"
      profile=$1
      client=$2
      file=$3
      object_key=$(get_uploaded_key "$file")
      out_file="/tmp/$object_key"

      case "$client" in
      "aws-s3api" | "aws")
        When run aws --profile $profile s3api get-object --bucket $BUCKET_NAME --key $object_key $out_file
        The output should include "ETag"
        ;;
      "aws-s3")
        When run aws --profile $profile s3 cp "s3://$BUCKET_NAME/$object_key" $out_file
        The output should include "download: s3://$BUCKET_NAME/$object_key"
        The output should include "$out_file"
        ;;
      "rclone")
        When run rclone copyto $profile:$BUCKET_NAME/$object_key $out_file -v --no-check-dest
        The error should include "$object_key: Copied"
        ;;
      esac
      The status should be success
    End
  End
End
Describe 'List Objects' category:"Object Management" id:"061"
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "from bucket $BUCKET_NAME of profile $1, using client $2."
    profile=$1
    client=$2
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile $profile s3api list-objects --bucket $BUCKET_NAME
      for file in $FILES;do
        object_key=$(get_uploaded_key "$file")
        The output should include "\"Key\": \"$object_key\","
      done
      ;;
    "aws-s3")
      When run aws --profile $profile s3 ls "s3://$BUCKET_NAME"
      for file in $FILES;do
        object_key=$(get_uploaded_key "$file")
        The output should include " $object_key"
      done
      ;;
    "rclone")
      When run rclone ls $profile:$BUCKET_NAME
      for file in $FILES;do
        object_key=$(get_uploaded_key "$file")
        The output should include " $object_key"
      done
      ;;
    esac
    The status should be success
  End
End

first_file="${FILES%% *}"
remaining_files="${FILES#* }"

Describe 'Delete' category:"Object Management"
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Describe "Objects"
  Example "on profile $1, using client $2, delete file $first_file on bucket $BUCKET_NAME" id:"062"
    profile=$1
    client=$2
    object_key=$(get_uploaded_key "$first_file")
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile "$profile" s3api delete-object --bucket "$BUCKET_NAME" --key "$object_key" --debug
      The error should include "$object_key HTTP/1.1\" 204"
      ;;
    "aws-s3")
      When run aws --profile $profile s3 rm "s3://$BUCKET_NAME/$object_key"
      The output should include "delete: s3://$BUCKET_NAME/$object_key"
      ;;
    "rclone")
      When run rclone deletefile "$profile:$BUCKET_NAME/$object_key" -v
      The error should include "$object_key: Deleted"
      ;;
    esac
    The status should be success
  End
  End
  Describe "Objects in batch"
  Example "on profile $1, using client $2, batch delete files $remaining_files on bucket $BUCKET_NAME" id:"063"
    profile=$1
    client=$2
    objects=""
    for file in $remaining_files; do
      object_key=$(get_uploaded_key "$file")
      objects+="$object_key "
    done
    case "$client" in
    "aws-s3api" | "aws")
      s3api_objects="Objects=["
      for object_key in $objects; do
        s3api_objects+="{Key=$object_key},"
      done
      s3api_objects+="]"

      When run aws --profile "$profile" s3api delete-objects --bucket "$BUCKET_NAME" --delete "$s3api_objects"
      for object_key in $objects; do
        The output should include "\"Key\": \"$object_key\""
      done
      ;;
    "aws-s3")
      s3_args=''
      for object_key in $objects; do
        s3_args+=" --include $object_key"
      done

      When run aws --profile $profile s3 rm "s3://$BUCKET_NAME/" --recursive --exclude "*" $s3_args
      for object_key in $objects; do
        The output should include "delete: s3://$BUCKET_NAME/$object_key"
      done
      ;;
    "rclone")
      # convert space separated list to comma separated
      rclone_objects="${objects// /,}"

      When run rclone delete "$profile:$BUCKET_NAME" --include "{$rclone_objects}" --dump headers
      for object_key in $objects; do
        The error should include "$object_key: Deleted"
      done
      ;;
    esac
    The status should be success
  End
  End
End

teardown(){
  for profile in $PROFILES; do
    remove_test_bucket $profile $UNIQUE_SUFIX
  done
}
teardown
