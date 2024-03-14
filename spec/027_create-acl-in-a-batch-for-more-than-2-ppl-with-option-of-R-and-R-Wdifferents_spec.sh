Describe 'Create ACL in a batch for more than 2 ppl with option of R and R/W differents:' category:"Bucket Permission"
  setup(){
    bucket_name="test-027-$(date +%s)"
    file1_name="LICENSE"
    id="fake-user"
    id2="fake-user"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"027"
    profile=$1
    aws --profile $profile s3 mb s3://$bucket_name
    When run aws s3api --profile $profile put-bucket-acl --bucket $bucket_name --grant-write id=$id --grant-read id=$id2
    The status should be success
    The output should include ""
    aws s3 rb s3://$bucket_name --profile $profile --force
  End
End
