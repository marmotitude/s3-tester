# 065: Delete versioned object

#constants
% UNIQUE_SUFIX: $(date +%s)

Include ./spec/053_utils.sh # import functions: get_test_bucket_name, get_uploaded_key
Include ./spec/054_utils.sh # import functions: exist_var

Describe "setup 065" category:"Object Management" id:"065"
  Parameters:matrix
    $PROFILES
  End
  # create test bucket
  Example "create test bucket for profile $1 using rclone"
    profile=$1
    bucket_name=$(get_test_bucket_name)
    When run rclone mkdir "$profile:$bucket_name"
    The status should be success
  End
  Example "enable versioning on test bucket of profile $1 using aws-cli"
    profile=$1
    bucket_name=$(get_test_bucket_name)
    When run aws s3api put-bucket-versioning --bucket "$bucket_name" --profile "$profile" --versioning-configuration Status=Enabled
    The status should be success
  End
  Example "upload object on versioning-enabled bucket of profile $1 using aws-cli"
    profile=$1
    bucket_name=$(get_test_bucket_name)
    local_file="LICENSE"
    key=$(get_uploaded_key "$local_file")
    When run aws --profile $profile s3api put-object --bucket $bucket_name --body $local_file --key $key
    The status should be success
    The output should include "ETag"
  End
  Example "overwrite object on versioning-enabled bucket of profile $1 using aws-cli"
    profile=$1
    bucket_name=$(get_test_bucket_name)
    key=$(get_uploaded_key "LICENSE")
    other_local_file="README.md"
    When run aws --profile $profile s3api put-object --bucket $bucket_name --body $other_local_file --key $key
    The status should be success
    The output should include "ETag"
  End
  Example "list versions should have versions"
    profile=$1
    bucket_name=$(get_test_bucket_name)
    When run aws --profile $profile s3api list-object-versions --bucket $bucket_name
    The status should be success
    The output should include "Versions"
  End
End
  

Describe "Delete versioned object" category:"Object Management" id:"065"
  Parameters:matrix
    $PROFILES
  End
  Example "delete object on versioning-enabled bucket of profile $1 using aws-cli"
    profile=$1
    bucket_name=$(get_test_bucket_name)
    local_file="LICENSE"
    key=$(get_uploaded_key "$local_file")
    When run aws --profile $profile s3api delete-object --bucket $bucket_name --key $key --debug
    The status should be success
    The error should include "DELETE /$bucket_name/$key HTTP/1.1\" 204 0"
  End
  Example "list versions should have a delete marker"
    profile=$1
    bucket_name=$(get_test_bucket_name)
    When run aws --profile $profile s3api list-object-versions --bucket $bucket_name
    The status should be success
    The output should include "DeleteMarkers"
  End
End

Describe "teardown 065" category:"Object Management" id:"065"
  Parameters:matrix
    $PROFILES
  End
  # delete test bucket, if created
  Skip if "A test bucket was provided" exists_var "TEST_BUCKET_NAME"
  Example "delete test bucket for profile $1 using rclone"
    profile=$1
    bucket_name=$(get_test_bucket_name)
    When run rclone purge "$profile:$bucket_name"
    The status should be success
  End
End
