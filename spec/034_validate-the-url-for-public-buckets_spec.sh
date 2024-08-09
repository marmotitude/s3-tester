Describe 'Validate the URL for public buckets:' category:"Bucket Sharing"
  setup(){
    bucket_name="test-034-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"034"
    profile=$1
    client=$2
    endpoint_url=$(aws configure get $profile.endpoint_url)
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client --acl public-read  > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    When run curl ${endpoint_url}${bucket_name-$client}
    The output should include ListBucketResult
    The error should include Current
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      Skip "Skipped test to $client"
      ;;
    esac
    The status should be success
    rclone purge --log-file /dev/null "$profile:$bucket_name-$client" > /dev/null
  End
End
