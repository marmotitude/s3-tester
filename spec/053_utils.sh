get_test_bucket_name(){
  if [[ -n $TEST_BUCKET_NAME ]];then
    echo "$TEST_BUCKET_NAME"
  else
    echo "test-$profile-$UNIQUE_SUFIX"
  fi
}
get_uploaded_key(){
  echo "test--$profile--$client--$1--$UNIQUE_SUFIX"
}
remove_test_bucket(){
  profile=$1
  bucket_name=$(get_test_bucket_name)
  if [[ -z $TEST_BUCKET_NAME ]];then
    #echo "removing bucket $bucket_name..."
    aws --profile "$profile" s3 rb "s3://${bucket_name}" --force > /dev/null
  else
    rclone_objects=""
    for file in $FILES; do
      for client in $CLIENTS; do
        object_key=$(get_uploaded_key "$file")
        rclone_objects+="$object_key,"
      done
    done
    #echo "remove objects $rclone_objects from $profile / $bucket_name..."
    rclone delete "$profile:$bucket_name" --include "{$rclone_objects}" > /dev/null
  fi
}
