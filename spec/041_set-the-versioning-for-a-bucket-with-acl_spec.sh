Describe 'Set the versioning for a bucket with ACL:' category:"Object Versioning"
  setup(){
    bucket_name="test-041-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"041"
    profile=$1
    id="fake-user"
    aws --profile $profile s3 mb s3://$bucket_name
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name --grant-write id=$id --grant-read id=$id
    When run aws s3api --profile $profile put-bucket-versioning --bucket $bucket_name --versioning-configuration Status=Enabled
    The status should be success
    The output should include ""
    aws --profile $profile s3 rb s3://$bucket_name --force
  End
End
