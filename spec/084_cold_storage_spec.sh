# TODO: ways of setting storage class on AWS S3
#   NEW OBJECT: 
#     initiate multipart upload with storage-class header
#     NO SUPPORT post object with storage-class header
#
#   EXISTING OBJECT:
#     put object copy operation: same key name, same bucket e metadata-directive header COPY
#       and storage-class header
#     on versioned bucket a copy creates a new version, changing the storage class of a version is not possible 
#
#
% UNIQUE_SUFIX: $(date +%s)

# import functions: get_test_bucket_name, get_uploaded_key, remove_test_bucket
Include ./spec/053_utils.sh
# import functions: exist_var create_file
Include ./spec/054_utils.sh

# - copy object with GLACIER_IR storage class to the same bucket with the same key but storage class STANDARD
#   - check that the storage class is STANDARD
# - copy object with STANDARD storage class to the same bucket with the same key but storage class GLACIER_IR
#   - check that the storage class is GLACIER_IR
# - OK teardown: remove bucket

Describe 'Setup 84, 85, 86, 87'
  Parameters:matrix
    $PROFILES
  End
  Example "create test bucket using rclone" id:"084" id:"085" id:"087"
    profile=$1
    bucket_name=$(get_test_bucket_name)
    When run rclone mkdir "$profile:$bucket_name"
    The status should be success
  End
End

Describe 'Put object with storage class' category:"Cold Storage" id:"084" id:"085"
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "default, on profile $1 using client $2"
    profile=$1
    client=$2
    bucket_name=$(get_test_bucket_name)
    object_key=$(get_uploaded_key "default-class")
    file="LICENSE"
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile "$profile" s3api put-object --bucket "$bucket_name" --key "$object_key" --body "$file"
      The status should be success
      The output should include "\"ETag\":"
      ;;
    "aws-s3")
      When run aws --profile "$profile" s3 cp "$file" "s3://$bucket_name/$object_key"
      The status should be success
      The output should include "upload: ./$file to s3://$bucket_name/$object_key"
      ;;
    "rclone")
      When run rclone copyto "$file" "$profile:$bucket_name/$object_key" -v
      The status should be success
      The error should include "INFO  : $file: Copied"
      ;;
    "mgc")
      ;;
    esac
  End
  Example "STANDARD, on profile $1 using client $2"
    profile=$1
    client=$2
    bucket_name=$(get_test_bucket_name)
    object_key=$(get_uploaded_key "standard-class")
    file="LICENSE"
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile "$profile" s3api put-object --bucket "$bucket_name" --key "$object_key" --storage-class "STANDARD" --body "$file"
      The status should be success
      The output should include "\"ETag\":"
      ;;
    "aws-s3")
      When run aws --profile "$profile" s3 cp "$file" "s3://$bucket_name/$object_key" --storage-class "STANDARD"
      The status should be success
      The output should include "upload: ./$file to s3://$bucket_name/$object_key"
      ;;
    "rclone")
      When run rclone copyto "$file" "$profile:$bucket_name/$object_key" --s3-storage-class "STANDARD" -v
      The status should be success
      The error should include "INFO  : $file: Copied"
      ;;
    "mgc")
      ;;
    esac
  End
  Example "GLACIER_IR, on profile $1 using client $2"
    profile=$1
    client=$2
    bucket_name=$(get_test_bucket_name)
    object_key=$(get_uploaded_key "glacier-ir-class")
    file="LICENSE"
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile "$profile" s3api put-object --bucket "$bucket_name" --key "$object_key" --storage-class "GLACIER_IR" --body "$file"
      The status should be success
      The output should include "\"ETag\":"
      ;;
    "aws-s3")
      When run aws --profile "$profile" s3 cp "$file" "s3://$bucket_name/$object_key" --storage-class "GLACIER_IR"
      The status should be success
      The output should include "upload: ./$file to s3://$bucket_name/$object_key"
      ;;
    "rclone")
      When run rclone copyto "$file" "$profile:$bucket_name/$object_key" --s3-storage-class "GLACIER_IR" -v
      The status should be success
      The error should include "INFO  : $file: Copied"
      ;;
    "mgc")
      ;;
    esac
  End
End
Describe 'List object with storage class' category:"Cold Storage" id:"085"
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "default, on profile $1 using client $2"
    profile=$1
    client=$2
    bucket_name=$(get_test_bucket_name)
    object_key=$(get_uploaded_key "default-class")
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws s3api list-objects-v2 --profile "$profile" --bucket "$bucket_name" --prefix "$object_key" --query "Contents[*].StorageClass"
      The status should be success
      The output should include "\"STANDARD\""
      ;;
    "rclone")
      When run rclone lsjson --metadata "$profile:$bucket_name/$object_key"
      The status should be success
      The output should include "STANDARD"
      ;;
    "mgc")
      ;;
    esac
  End
  Example "STANDARD, on profile $1 using client $2"
    profile=$1
    client=$2
    bucket_name=$(get_test_bucket_name)
    object_key=$(get_uploaded_key "standard-class")
    case "$client" in
    "aws-s3api" | "aws")
      When run aws s3api list-objects-v2 --profile "$profile" --bucket "$bucket_name" --prefix "$object_key" --query "Contents[*].StorageClass"
      The status should be success
      The output should include "\"STANDARD\""
      ;;
    "aws-s3")
      ;;
    "rclone")
      When run rclone lsjson --metadata "$profile:$bucket_name/$object_key"
      The status should be success
      The output should include "STANDARD"
      ;;
    "mgc")
      ;;
    esac
  End
  Example "GLACIER_IR, on profile $1 using client $2"
    profile=$1
    client=$2
    bucket_name=$(get_test_bucket_name)
    object_key=$(get_uploaded_key "glacier-ir-class")
    case "$client" in
    "aws-s3api" | "aws")
      When run aws s3api list-objects-v2 --profile "$profile" --bucket "$bucket_name" --prefix "$object_key" --query "Contents[*].StorageClass"
      The status should be success
      The output should include "\"GLACIER_IR\""
      ;;
    "aws-s3")
      ;;
    "rclone")
      When run rclone lsjson --metadata "$profile:$bucket_name/$object_key"
      The status should be success
      The output should include "GLACIER_IR"
      ;;
    "mgc")
      ;;
    esac
  End
End

Describe 'Multipart upload with storage class' category:"Cold Storage" id:"087"
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "default, on profile $1 using client $2"
    profile=$1
    client=$2
    bucket_name=$(get_test_bucket_name)
    object_key=$(get_uploaded_key "multipart-default-class")
    local_file="" # will be overwritten by the function below
    file_size=6
    file_unit="mb"
    create_file "$file_size" "$file_unit"
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")

    # initiates a multipart upload without passing a storage class argument
    upload_id=$(aws s3api create-multipart-upload --profile "$profile" --bucket "$bucket_name" --key "$object_key" | jq .UploadId -r)
    # upload two parts
    aws s3api upload-part --profile "$profile" --bucket "$bucket_name" --key "$object_key" --upload-id "$upload_id" --body "$local_file" --part-number 1
    aws s3api upload-part --profile "$profile" --bucket "$bucket_name" --key "$object_key" --upload-id "$upload_id" --body "$local_file" --part-number 2
    # generates a parts list json file
    aws s3api list-parts --profile "$profile" --bucket "$bucket_name" --key "$object_key" --upload-id "$upload_id" | jq '{"Parts": [.Parts[] | {"PartNumber": .PartNumber, "ETag": .ETag}]}' > /tmp/parts.json
    # complete the multipart upload
    When run aws s3api complete-multipart-upload --profile "$profile" --bucket "$bucket_name" --key "$object_key" --upload-id $upload_id --multipart-upload file:///tmp/parts.json
    The status should be success
    The output should include "\"Key\": \"$object_key\""
      ;;
    "rclone")
      ;;
    "mgc")
      ;;
    esac
  End
  Example "STANDARD, on profile $1 using client $2"
    profile=$1
    client=$2
    bucket_name=$(get_test_bucket_name)
    object_key=$(get_uploaded_key "multipart-standard-class")
    local_file="" # will be overwritten by the function below
    file_size=6
    file_unit="mb"
    create_file "$file_size" "$file_unit"
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")

    # initiates a multipart upload without passing a storage class argument
    upload_id=$(aws s3api create-multipart-upload --storage-class STANDARD --profile "$profile" --bucket "$bucket_name" --key "$object_key" | jq .UploadId -r)
    # upload two parts
    aws s3api upload-part --profile "$profile" --bucket "$bucket_name" --key "$object_key" --upload-id "$upload_id" --body "$local_file" --part-number 1
    aws s3api upload-part --profile "$profile" --bucket "$bucket_name" --key "$object_key" --upload-id "$upload_id" --body "$local_file" --part-number 2
    # generates a parts list json file
    aws s3api list-parts --profile "$profile" --bucket "$bucket_name" --key "$object_key" --upload-id "$upload_id" | jq '{"Parts": [.Parts[] | {"PartNumber": .PartNumber, "ETag": .ETag}]}' > /tmp/parts.json
    # complete the multipart upload
    When run aws s3api complete-multipart-upload --profile "$profile" --bucket "$bucket_name" --key "$object_key" --upload-id $upload_id --multipart-upload file:///tmp/parts.json
    The status should be success
    The output should include "\"Key\": \"$object_key\""
      ;;
    "rclone")
      ;;
    "mgc")
      ;;
    esac
  End
  Example "GLACIER_IR, on profile $1 using client $2"
    profile=$1
    client=$2
    bucket_name=$(get_test_bucket_name)
    object_key=$(get_uploaded_key "multipart-glacier-ir-class")
    local_file="" # will be overwritten by the function below
    file_size=6
    file_unit="mb"
    create_file "$file_size" "$file_unit"
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")

    # initiates a multipart upload without passing a storage class argument
    upload_id=$(aws s3api create-multipart-upload --storage-class GLACIER_IR --profile "$profile" --bucket "$bucket_name" --key "$object_key" | jq .UploadId -r)
    # upload two parts
    aws s3api upload-part --profile "$profile" --bucket "$bucket_name" --key "$object_key" --upload-id "$upload_id" --body "$local_file" --part-number 1
    aws s3api upload-part --profile "$profile" --bucket "$bucket_name" --key "$object_key" --upload-id "$upload_id" --body "$local_file" --part-number 2
    # generates a parts list json file
    aws s3api list-parts --profile "$profile" --bucket "$bucket_name" --key "$object_key" --upload-id "$upload_id" | jq '{"Parts": [.Parts[] | {"PartNumber": .PartNumber, "ETag": .ETag}]}' > /tmp/parts.json
    # complete the multipart upload
    When run aws s3api complete-multipart-upload --profile "$profile" --bucket "$bucket_name" --key "$object_key" --upload-id $upload_id --multipart-upload file:///tmp/parts.json
    The status should be success
    The output should include "\"Key\": \"$object_key\""
      ;;
    "rclone")
      ;;
    "mgc")
      ;;
    esac
  End
End

Describe 'List multipart object with storage class' category:"Cold Storage" id:"087"
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "default, on profile $1 using client $2"
    profile=$1
    client=$2
    bucket_name=$(get_test_bucket_name)
    object_key=$(get_uploaded_key "multipart-default-class")
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws s3api list-objects-v2 --profile "$profile" --bucket "$bucket_name" --prefix "$object_key" --query "Contents[*].StorageClass"
      The status should be success
      The output should include "\"STANDARD\""
      ;;
    "rclone")
      # When run rclone lsjson --metadata "$profile:$bucket_name/$object_key"
      # The status should be success
      # The output should include "STANDARD"
      ;;
    "mgc")
      ;;
    esac
  End
  Example "STANDARD, on profile $1 using client $2"
    profile=$1
    client=$2
    bucket_name=$(get_test_bucket_name)
    object_key=$(get_uploaded_key "multipart-standard-class")
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws s3api list-objects-v2 --profile "$profile" --bucket "$bucket_name" --prefix "$object_key" --query "Contents[*].StorageClass"
      The status should be success
      The output should include "\"STANDARD\""
      ;;
    "rclone")
      # When run rclone lsjson --metadata "$profile:$bucket_name/$object_key"
      # The status should be success
      # The output should include "STANDARD"
      ;;
    "mgc")
      ;;
    esac
  End
  Example "GLACIER_IR, on profile $1 using client $2"
    profile=$1
    client=$2
    bucket_name=$(get_test_bucket_name)
    object_key=$(get_uploaded_key "multipart-glacier-ir-class")
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws s3api list-objects-v2 --profile "$profile" --bucket "$bucket_name" --prefix "$object_key" --query "Contents[*].StorageClass"
      The status should be success
      The output should include "\"GLACIER_IR\""
      ;;
    "rclone")
      # When run rclone lsjson --metadata "$profile:$bucket_name/$object_key"
      # The status should be success
      # The output should include "GLACIER_IR"
      ;;
    "mgc")
      ;;
    esac
  End
End

teardown(){
  remove_test_bucket $profile $UNIQUE_SUFIX
}
Describe 'Teardown 84, 85, 86, 87'
  Parameters:matrix
    $PROFILES
  End
  Example "remove test bucket or test bucket contents" id:"085" id:"085" id:"087"
    profile=$1
    When call teardown
    The status should be success
  End
End
