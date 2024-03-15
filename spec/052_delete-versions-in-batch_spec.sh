Describe 'Delete versions in batch:' category:"Object Versioning"
  setup(){
    bucket_name="test-052-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"052"
    profile=$1
    client=$2 
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client| jq
    aws s3api --profile $profile put-bucket-versioning --bucket $bucket_name-$client --versioning-configuration Status=Enabled
    aws --profile $profile s3 cp $file1_name  s3://$bucket_name-$client
    aws --profile $profile s3 cp $file1_name  s3://$bucket_name-$client
    When run aws --profile $profile s3api delete-objects --bucket $bucket_name-$client --delete "$(aws --profile $profile s3api list-object-versions --bucket $bucket_name-$client| jq '{Objects: [.Versions[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')"
    The output should include "Deleted"
    aws --profile $profile s3 rb s3://$bucket_name-$client --force
  End
End