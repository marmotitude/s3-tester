Describe 'Create a ACL read/write for a bucket:' category:"Bucket Permission"
  setup(){
    bucket_name="test-026-$(date +%s)"
    file1_name="LICENSE"
    id="fake-user"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"026"
    profile=$1
    client=$2
    aws --profile $profile s3 mb s3://$bucket_name-$client
    When run aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-write id=$id --grant-read id=$id
    The status should be success
    The output should include ""
    aws s3 rb s3://$bucket_name-$client --profile $profile --force
  End
End
