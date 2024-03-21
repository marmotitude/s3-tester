get_test_bucket_name(){
    if [[ -n $TEST_BUCKET_NAME ]];then
      echo "$TEST_BUCKET_NAME"
    else
      echo "test-$UNIQUE_SUFIX"
    fi
}
create_test_bucket(){
  if [[ -z $TEST_BUCKET_NAME ]];then
    profile=$1
    bucket_name=$(get_test_bucket_name)
    echo "creating new bucket $bucket_name on profile $profile..."
    aws --profile $profile s3api create-bucket --bucket $bucket_name > /dev/null
  fi
}
remove_test_bucket(){
  if [[ -z $TEST_BUCKET_NAME ]];then
    profile=$1
    bucket_name=$(get_test_bucket_name)
    echo "removing bucket $bucket_name..."
    aws --profile "$profile" s3 rb "s3://${bucket_name}" --force > /dev/null
  fi
}
