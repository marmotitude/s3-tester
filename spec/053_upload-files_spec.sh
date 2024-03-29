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

# import functions: get_test_bucket_name, get_uploaded_key, remove_test_bucket
Include ./spec/053_utils.sh

# constants
% UNIQUE_SUFIX: $(date +%s)
% FILES: "LICENSE README.md test.sh"

Describe 'Setup 53,57,61,62,63'
  Parameters:matrix
    $PROFILES
  End
  Example "create test bucket using rclone" id:"053" id:"057" id:"061" id:"062" id:"063"
    profile=$1
    bucket_name=$(get_test_bucket_name)
    # rclone wont exit 1 even if the bucket exists, which makes this action indepotent
    When run rclone mkdir "$profile:$bucket_name"
    The status should be success
  End
End

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
    BUCKET_NAME=$(get_test_bucket_name)
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
    "mgc")
      mgc profile set-current $profile > /dev/null
      When run mgc object-storage objects upload --src="$local_file" --dst="$BUCKET_NAME/$key"
      The status should be success
      The output should include "Uploaded file $local_file to $BUCKET_NAME/$keys3"
      ;;
    esac
  End
  Describe 'Download Files' category:"Object Management" id:"057"
    Example "from test bucket of profile $1, The file $3, using client $2"
      profile=$1
      client=$2
      file=$3
      BUCKET_NAME=$(get_test_bucket_name)
      object_key=$(get_uploaded_key "$file")
      out_file="/tmp/$object_key"

      case "$client" in
      "aws-s3api" | "aws")
        When run aws --profile $profile s3api get-object --bucket $BUCKET_NAME --key $object_key $out_file
        The output should include "ETag"
        The status should be success
        ;;
      "aws-s3")
        When run aws --profile $profile s3 cp "s3://$BUCKET_NAME/$object_key" $out_file
        The output should include "download: s3://$BUCKET_NAME/$object_key"
        The output should include "$out_file"
        The status should be success
        ;;
      "rclone")
        When run rclone copyto $profile:$BUCKET_NAME/$object_key $out_file -v --no-check-dest
        The error should include "$object_key: Copied"
        The status should be success
        ;;
      "mgc")
        mgc profile set-current $profile > /dev/null
        When run mgc object-storage objects download --dst="$out_file" --src="$BUCKET_NAME/$object_key"
        The status should be success
        The output should include "Downloaded from $BUCKET_NAME/$object_key to $out_file"
        ;;
      esac
    End
  End
End
Describe 'List Objects' category:"Object Management" id:"061"
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "from test bucket of profile $1, using client $2."
    profile=$1
    client=$2
    BUCKET_NAME=$(get_test_bucket_name)
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile $profile s3api list-objects --bucket $BUCKET_NAME
      The status should be success
      for file in $FILES;do
        object_key=$(get_uploaded_key "$file")
        The output should include "\"Key\": \"$object_key\","
      done
      ;;
    "aws-s3")
      When run aws --profile $profile s3 ls "s3://$BUCKET_NAME"
      The status should be success
      for file in $FILES;do
        object_key=$(get_uploaded_key "$file")
        The output should include " $object_key"
      done
      ;;
    "rclone")
      When run rclone ls $profile:$BUCKET_NAME
      The status should be success
      for file in $FILES;do
        object_key=$(get_uploaded_key "$file")
        The output should include " $object_key"
      done
      ;;
    "mgc")
      mgc profile set-current $profile > /dev/null
      When run mgc object-storage objects list --dst="$BUCKET_NAME"
      The status should be success
      for file in $FILES;do
        object_key=$(get_uploaded_key "$file")
        The output should include " $object_key"
      done
      ;;
    esac
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
  Example "on profile $1, using client $2, delete file $first_file on test bucket" id:"062"
    profile=$1
    client=$2
    BUCKET_NAME=$(get_test_bucket_name)
    object_key=$(get_uploaded_key "$first_file")
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile "$profile" s3api delete-object --bucket "$BUCKET_NAME" --key "$object_key" --debug
      The status should be success
      The error should include "$object_key HTTP/1.1\" 204"
      ;;
    "aws-s3")
      When run aws --profile $profile s3 rm "s3://$BUCKET_NAME/$object_key"
      The status should be success
      The output should include "delete: s3://$BUCKET_NAME/$object_key"
      ;;
    "rclone")
      When run rclone deletefile "$profile:$BUCKET_NAME/$object_key" -v
      The status should be success
      The error should include "$object_key: Deleted"
      ;;
    "mgc")
      mgc profile set-current $profile > /dev/null
      When run mgc --debug object-storage objects delete --dst="$BUCKET_NAME/$object_key" --cli.bypass-confirmation
      The status should be success
      The error should include "$BUCKET_NAME?delete="
      The error should include "200 OK"
      ;;
    esac
  End
  End
  Describe "Objects in batch"
    Example "on profile $1, using client $2, batch delete files $remaining_files on bucket $BUCKET_NAME" id:"063"
      profile=$1
      client=$2
      BUCKET_NAME=$(get_test_bucket_name)
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
          The status should be success
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
          The status should be success
          The output should include "delete: s3://$BUCKET_NAME/$object_key"
        done
        ;;
      "rclone")
        # convert space separated list to comma separated
        rclone_objects="${objects// /,}"

        When run rclone delete "$profile:$BUCKET_NAME" --include "{$rclone_objects}" --dump headers
        for object_key in $objects; do
          The status should be success
          The error should include "$object_key: Deleted"
        done
        ;;
      "mgc")
        mgc profile set-current $profile > /dev/null
        mgc_objects="[{}"
        for object_key in $objects; do
          mgc_objects+=',{"include": "'
          mgc_objects+=$object_key
          mgc_objects+='"}'
        done
        mgc_objects+="]"
        # TODO: mgc is not properly supporting --include lists, see https://chat.google.com/room/AAAATfofxEQ/HiM7LN_4CUw/HiM7LN_4CUw?cls=10
        When run mgc object-storage objects delete-all "$BUCKET_NAME" --cli.bypass-confirmation --filter="$mgc_objects"
        The status should be success
        The output should include "Deleting objects from \"$BUCKET_NAME\""
        ;;
      esac
    End
    Example "on profile $1, list objects on bucket $BUCKET_NAME DONT include files:$remaining_files" id:"063"
      profile=$1
      client=$2
      BUCKET_NAME=$(get_test_bucket_name)
      When run aws --profile $profile s3api list-objects --bucket $BUCKET_NAME
      The status should be success
      for file in $remaining_files;do
        object_key=$(get_uploaded_key "$file")
        The output should not include "\"Key\": \"$object_key\","
      done
    End
  End
End

teardown(){
  remove_test_bucket $profile $UNIQUE_SUFIX
}
Describe 'Teardown 53,57,61,62,63'
  Parameters:matrix
    $PROFILES
  End
  Example "remove test bucket or test bucket contents" id:"053" id:"057" id:"061" id:"062" id:"063"
    profile=$1
    When call teardown
    The status should be success
  End
End
