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
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client > /dev/null
    aws s3api --profile $profile put-bucket-versioning --bucket $bucket_name-$client --versioning-configuration Status=Enabled > /dev/null
    aws --profile $profile s3 cp $file1_name  s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3 cp $file1_name  s3://$bucket_name-$client > /dev/null
    sleep 10
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    When run aws --profile $profile s3api delete-objects --bucket $bucket_name-$client --delete "$(aws --profile $profile s3api list-object-versions --bucket $bucket_name-$client| jq '{Objects: [.Versions[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')"
    The status should be success
    The output should include "Deleted"
      ;;
    "rclone")
    aws --profile $profile s3api delete-objects --bucket $bucket_name-$client --delete "$(aws --profile $profile s3api list-object-versions --bucket $bucket_name-$client| jq '{Objects: [.Versions[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')" > /dev/null
    Skip "Skipped test to $client"
      ;;
    "mgc")
    aws --profile $profile s3api delete-objects --bucket $bucket_name-$client --delete "$(aws --profile $profile s3api list-object-versions --bucket $bucket_name-$client| jq '{Objects: [.Versions[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')" > /dev/null
    Skip "Skipped test to $client"
      ;;
    esac
    rclone purge --log-file /dev/null "$profile:$bucket_name-$client" > /dev/null
  End
End
