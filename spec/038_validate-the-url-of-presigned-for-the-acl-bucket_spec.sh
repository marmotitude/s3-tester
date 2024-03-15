Describe 'Validate the URL of presigned for the ACL bucket:' category:"Bucket Sharing"  
  setup(){
    bucket_name="test-038-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"038"
    profile=$1
    id="fake-user"
    aws --profile $profile s3 mb s3://$bucket_name
    aws --profile $profile s3 cp $file1_name s3://$bucket_name
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name --grant-write id=$id --grant-read id=$id
    presign_url=$(aws --profile $profile s3 presign s3://$bucket_name/$file1_name)
    When run curl $presign_url
    The status should be success
    The output should include Copyright
    The error should include Current
    aws --profile $profile s3 rb s3://$bucket_name --force
  End
End
