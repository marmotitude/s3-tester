create_bucket() {
    while true; do
        bucket_name="test-095-setup-$(date +%s)"
        test_bucket_name="$bucket_name-$client-$profile"

        aws --profile "$profile" s3 mb "s3://$bucket_name" > /dev/null 2>&1

        if [ $? -ne 0 ]; then
            break
        fi
    done
}

Describe 'Create 100 buckets:' category:"Skip"
  setup(){
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"095"
    profile=$1
    client=$2
    create_bucket || true
    bucket_name="test-095-$(date +%s)"
    test_bucket_name="$bucket_name-$client-$profile"
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile s3 mb s3://$test_bucket_name
      The stderr should include TooManyBuckets
      ;;
    "rclone")
      When run rclone mkdir $profile:$test_bucket_name -v
      The stderr should include TooManyBuckets
      ;;
    "mgc")
      mgc workspace set $profile > /dev/null
      When run mgc object-storage buckets create $test_bucket_name --raw
      The stderr should include TooManyBuckets
      ;;
    esac
    The status should be failure
    aws s3 ls --profile $profile | awk '$3 ~ /^test-095-setup/ {print $3}' | xargs -I {} aws --profile $profile s3 rb s3://{} --force > /dev/null
  End
End
