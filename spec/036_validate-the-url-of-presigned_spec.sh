Describe 'get-presign:' category:"Bucket Sharing"
  setup(){
    bucket_name="test-036-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"036"
    profile=$1
    client=$2
    aws --profile $profile s3 mb s3://$bucket_name-$client
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client
    presign_url=$(aws --profile $profile s3 presign s3://$bucket_name-$client/$file1_name)
    When run curl $presign_url
    The status should be success
    The output should include Copyright
    The error should include Current
    aws s3 rb s3://$bucket_name-$client --profile $profile --force
  End
End
