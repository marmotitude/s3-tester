Describe 'Delete object with versions:' category:"Object Versioning"
  setup(){
    bucket_name="test-049-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"049"
    profile=$1
    client=$2
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client| jq
    aws s3api --profile $profile put-bucket-versioning --bucket $bucket_name-$client --versioning-configuration Status=Enabled
    aws --profile $profile s3 cp $file1_name  s3://$bucket_name-$client
    aws --profile $profile s3 cp $file1_name  s3://$bucket_name-$client
    When run aws --profile $profile s3 rm s3://$bucket_name-$client/$file1_name
    The output should include "delete"
    aws --profile $profile s3api delete-objects --bucket $bucket_name-$client --delete "$(aws --profile $profile s3api list-object-versions --bucket $bucket_name-$client| jq '{Objects: [.Versions[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')" | jq
    aws --profile $profile s3api delete-objects --bucket $bucket_name-$client --delete "$(aws --profile $profile s3api list-object-versions --bucket $bucket_name-$client| jq '{Objects: [.DeleteMarkers[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')" | jq
    aws --profile $profile s3 rb s3://$bucket_name-$client --force
      ;;
    "rclone")
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client| jq
    aws s3api --profile $profile put-bucket-versioning --bucket $bucket_name-$client --versioning-configuration Status=Enabled
    aws --profile $profile s3 cp $file1_name  s3://$bucket_name-$client
    aws --profile $profile s3 cp $file1_name  s3://$bucket_name-$client
    When run rclone delete $profile:$bucket_name-$client/$file1_name
    The output should include ""
    aws --profile $profile s3api delete-objects --bucket $bucket_name-$client --delete "$(aws --profile $profile s3api list-object-versions --bucket $bucket_name-$client| jq '{Objects: [.Versions[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')" | jq
    aws --profile $profile s3api delete-objects --bucket $bucket_name-$client --delete "$(aws --profile $profile s3api list-object-versions --bucket $bucket_name-$client| jq '{Objects: [.DeleteMarkers[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')" | jq
    aws --profile $profile s3 rb s3://$bucket_name-$client --force
      ;;
    esac
  End
End