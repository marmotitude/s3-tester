Describe 'Set the versioning for a private bucket:' category:"Object Versioning"
  setup(){
    bucket_name="test-040-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"040"
    profile=$1
    aws --profile $profile s3 mb s3://$bucket_name
    When run aws s3api --profile $profile put-bucket-versioning --bucket $bucket_name --versioning-configuration Status=Enabled
    The status should be success
    The output should include ""
    aws --profile $profile s3 rb s3://$bucket_name --force
  End
End
