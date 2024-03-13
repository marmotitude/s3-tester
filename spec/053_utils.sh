# utility function, returns the temporary bucket name to use if an existing one is not provided
get_bucket_name(){
  if [ -n "$should_purge_bucket" ]; then
    echo "test-053-$profile-$start_time"
  else
    echo $BUCKET_NAME
  fi
}

setup(){
  start_time=$(date +%s)
  # creates a temporary bucket for the tests if one is not provided
  if [ -z "$BUCKET_NAME" ]; then
    should_purge_bucket="yes"
    for profile in $PROFILES; do
      BUCKET_NAME=$(get_bucket_name)
      aws --profile $profile s3api create-bucket --bucket $BUCKET_NAME > /dev/null
    done
  fi
}

# delete the file uploaded in the test
delete_file(){
  if [ -z "$should_purge_bucket" ]; then
    aws --profile $profile s3 rm s3://$BUCKET_NAME/$key >/dev/null
  fi
}

# deletes the temporary test bucket if it was created
teardown(){
  for profile in $PROFILES; do
    BUCKET_NAME=$(get_bucket_name)
    if [ -n "$should_purge_bucket" ]; then
      aws --profile $profile s3 rb s3://$BUCKET_NAME --force > /dev/null
    fi
  done
}

