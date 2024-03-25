# Upload, Download big objects
#
# The test 054 is required for test 058 so they are linked. Filtering by the
# later will also run the former. Test 54 is the "setup" for test 58. The same
# is true for 055+059 and 056+060.
#
# The Download tests (058,059,060) also accepts an env var with `bucket/key`
# names, if passed the upload part is skipped, see env var names below.
#
# Tests:
#   - "054 Upload Files of  1GB" and "058 Download Files of  1GB"
#   - "055 Upload Files of  5GB" and "059 Download Files of  5GB"
#   - "056 Upload Files of 10GB" and "060 Download Files of 10GB"
#
# Env vars (optional):
#
#| Name               | Example                | Description                                 |
#|--------------------|------------------------|---------------------------------------------|
#| $TEST_BUCKET_NAME  | mybucketname           | an existing bucket to be reused             |
#| $OBJECT_URI_1GB    | mybucketname/my1GBkey  | an existing object of 1GB to be downloaded  |
#| $OBJECT_URI_5GB    | mybucketname/my5GBkey  | an existing object of 5GB to be downloaded  |
#| $OBJECT_URI_10GB   | mybucketname/my10Gkey  | an existing object of 10GB to be downloaded |
#
#-------------------------------------------------------------------------------

# import functions: get_test_bucket_name, create_test_bucket, remove_test_bucket
Include ./spec/053_utils.sh
# import function create_file
Include ./spec/054_utils.sh

# constants
% UNIQUE_SUFIX: $(date +%s)

setup(){
  file_size=$1
  file_unit=$2
  for profile in $PROFILES; do
    create_test_bucket $profile
  done
  BUCKET_NAME=$(get_test_bucket_name)
  create_file "$file_size" "$file_unit"
}

exists_var(){
  if [ -n "${!1}" ]; then
    return 0
  else
    return 1
  fi
}

file_size="1"
file_unit="gb"
Describe "of size ${file_size}${file_unit}"
  setup "$file_size" "$file_unit"

  Parameters:matrix
    $PROFILES
    $CLIENTS
  End

  Describe "Upload Files" category:"Object Management" id:"054" id:"058"
    #Skip if "Uploaded file exists" exists_1gb_file
    Skip if "Uploaded file exists" exists_var "OBJECT_URI_1GB"
    Example "on profile $1, using client $2, upload $local_file name $filename to bucket $BUCKET_NAME"
      profile=$1
      client=$2
      key="test-${profile}__${client}__${filename}"
      case "$client" in
      "aws-s3api" | "aws")
        When run aws --profile $profile s3api put-object --bucket $BUCKET_NAME --body $local_file --key $key
        The output should include "ETag"
        ;;
      "aws-s3")
        When run aws --profile $profile s3 cp $local_file "s3://$BUCKET_NAME/$key"
        The output should include "upload: "
        The output should include "$local_file to s3://$BUCKET_NAME/$key"
        ;;
      "rclone")
        When run rclone copyto $local_file $profile:$BUCKET_NAME/$key --no-check-dest -v
        The error should include " Copied"
        The error should include "to: $key"
        ;;
      esac
      The status should be success
    End
  End
  Describe "Download Files" category:"Object Management"
    Example "on profile $1, using client $2, download $filename from bucket $BUCKET_NAME" id:"058"
      profile=$1
      client=$2
      key="test-${profile}__${client}__${filename}"
      out_file="/tmp/$key"
      case "$client" in
      "aws-s3api" | "aws")
        When run aws --profile $profile s3api get-object --bucket $BUCKET_NAME --key $key $out_file
        The output should include "ETag"
        ;;
      "aws-s3")
        When run aws --profile $profile s3 cp "s3://$BUCKET_NAME/$key" $out_file
        The output should include "download: s3://$BUCKET_NAME/$key"
        The output should include "$out_file"
        ;;
      "rclone")
        When run rclone copyto $profile:$BUCKET_NAME/$key $out_file -v --no-check-dest
        The error should include "$object_key: "
        The error should include "Copied"
        The error should include ", 100%"
        ;;
      esac
      The status should be success
    End
  End
End
file_size="5"
Describe "of size ${file_size}${file_unit}"
  setup "$file_size" "$file_unit"

  Parameters:matrix
    $PROFILES
    $CLIENTS
  End

  Describe "Upload Files" category:"Object Management" id:"055" id:"059"
    Skip if "Uploaded file exists" exists_var "OBJECT_URI_5GB"
    Example "on profile $1, using client $2, upload $local_file name $filename to bucket $BUCKET_NAME"
      profile=$1
      client=$2
      key="test-${profile}__${client}__${filename}"
      case "$client" in
      "aws-s3api" | "aws")
        When run aws --profile $profile s3api put-object --bucket $BUCKET_NAME --body $local_file --key $key
        The output should include "ETag"
        ;;
      "aws-s3")
        When run aws --profile $profile s3 cp $local_file "s3://$BUCKET_NAME/$key"
        The output should include "upload: "
        The output should include "$local_file to s3://$BUCKET_NAME/$key"
        ;;
      "rclone")
        When run rclone copyto $local_file $profile:$BUCKET_NAME/$key --no-check-dest -v
        The error should include " Copied"
        The error should include "to: $key"
        ;;
      esac
      The status should be success
    End
  End
  Describe "Download Files" category:"Object Management"
    Example "on profile $1, using client $2, download $filename from bucket $BUCKET_NAME" id:"059"
      profile=$1
      client=$2
      key="test-${profile}__${client}__${filename}"
      out_file="/tmp/$key"
      case "$client" in
      "aws-s3api" | "aws")
        When run aws --profile $profile s3api get-object --bucket $BUCKET_NAME --key $key $out_file
        The output should include "ETag"
        ;;
      "aws-s3")
        When run aws --profile $profile s3 cp "s3://$BUCKET_NAME/$key" $out_file
        The output should include "download: s3://$BUCKET_NAME/$key"
        The output should include "$out_file"
        ;;
      "rclone")
        When run rclone copyto $profile:$BUCKET_NAME/$key $out_file -v --no-check-dest
        The error should include "$object_key: "
        The error should include "Copied"
        The error should include ", 100%"
        ;;
      esac
      The status should be success
    End
  End
End
file_size="10"
Describe "of size ${file_size}${file_unit}"
  setup "$file_size" "$file_unit"

  Parameters:matrix
    $PROFILES
    $CLIENTS
  End

  Describe "Upload Files" category:"Object Management" id:"056" id:"060"
    Skip if "Uploaded file exists" exists_var "OBJECT_URI_10GB"
    Example "on profile $1, using client $2, upload $local_file name $filename to bucket $BUCKET_NAME"
      profile=$1
      client=$2
      key="test-${profile}__${client}__${filename}"
      case "$client" in
      "aws-s3api" | "aws")
        When run aws --profile $profile s3api put-object --bucket $BUCKET_NAME --body $local_file --key $key
        The output should include "ETag"
        ;;
      "aws-s3")
        When run aws --profile $profile s3 cp $local_file "s3://$BUCKET_NAME/$key"
        The output should include "upload: "
        The output should include "$local_file to s3://$BUCKET_NAME/$key"
        ;;
      "rclone")
        When run rclone copyto $local_file $profile:$BUCKET_NAME/$key --no-check-dest -v
        The error should include " Copied"
        The error should include "to: $key"
        ;;
      esac
      The status should be success
    End
  End
  Describe "Download Files" category:"Object Management"
    Example "on profile $1, using client $2, download $filename from bucket $BUCKET_NAME" id:"060"
      profile=$1
      client=$2
      key="test-${profile}__${client}__${filename}"
      out_file="/tmp/$key"
      case "$client" in
      "aws-s3api" | "aws")
        When run aws --profile $profile s3api get-object --bucket $BUCKET_NAME --key $key $out_file
        The output should include "ETag"
        ;;
      "aws-s3")
        When run aws --profile $profile s3 cp "s3://$BUCKET_NAME/$key" $out_file
        The output should include "download: s3://$BUCKET_NAME/$key"
        The output should include "$out_file"
        ;;
      "rclone")
        When run rclone copyto $profile:$BUCKET_NAME/$key $out_file -v --no-check-dest
        The error should include "$object_key: "
        The error should include "Copied"
        The error should include ", 100%"
        ;;
      esac
      The status should be success
    End
  End
End
