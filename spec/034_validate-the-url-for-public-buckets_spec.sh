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
    endpoint_url=$(aws configure get $profile.endpoint_url)
    aws --profile $profile s3api create-bucket --bucket $bucket_name --acl public-read | jq
    When run curl $endpoint_url/$bucket_name
    The status should be success
    The output should include ListBucketResult
    The error should include Current
    aws s3 rb s3://$bucket_name --profile $profile --force
  End
End