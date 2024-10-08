# test if a profile is set on aws cli tool
check_missing_profile() {
  profile_arg=$1
  key_id=$(aws configure get profile.$profile_arg.aws_access_key_id)
  # true if key_id is null
  [ -z "$key_id" ]
}

# Function to check if bucket policy propagation has succeeded after a "put"
wait_for_policy_put() {
    bucket_name="$1"
    profile_name="$2"
    max_retries=5
    timeout_seconds=60
    success_count=0
    start_time=$(date +%s)

    while true; do
        # Check the bucket policy exists using AWS CLI
        if aws s3api get-bucket-policy --bucket "$bucket_name" --profile "$profile_name" > /dev/null 2>&1; then
            # Increment success counter on success
            success_count=$((success_count + 1))
            echo "Success $success_count"
        else
            # Reset success counter on failure
            success_count=0
            echo "Failed to get bucket policy"
        fi

        # Break the loop if successful 4 times in a row
        if [ "$success_count" -ge "$max_retries" ]; then
            echo "Bucket policy put has propagated successfully."
            break
        fi

        # Check if timeout has occurred
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))
        if [ "$elapsed_time" -ge "$timeout_seconds" ]; then
            echo "Timeout of 100 seconds reached."
            break
        fi

        # Wait for a while before next check
        sleep 2
    done
}

# Function to check if bucket policy eventual consistency has succeeded after a "delete"
wait_for_policy_delete() {
    bucket_name="$1"
    profile_name="$2"
    max_retries=7
    timeout_seconds=100
    success_count=0
    sleep_time=5
    start_time=$(date +%s)

    while true; do
        # Check the bucket policy no longer exists using AWS CLI
        if ! aws s3api get-bucket-policy --bucket "$bucket_name" --profile "$profile_name" > /dev/null 2>&1; then
            # Increment success counter on success (policy deleted)
            success_count=$((success_count + 1))
            echo "Success $success_count"
        else
            # Reset success counter on failure (policy still exists)
            success_count=0
            echo "Bucket policy still exists"
        fi

        # Break the loop if successful 4 times in a row
        if [ "$success_count" -ge "$max_retries" ]; then
            echo "Bucket policy delete has propagated successfully."
            break
        fi

        # Check if timeout has occurred
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))
        if [ "$elapsed_time" -ge "$timeout_seconds" ]; then
            echo "Timeout of 100 seconds reached."
            break
        fi

        # Wait for a while before next check
        sleep $sleep_time
    done
}
