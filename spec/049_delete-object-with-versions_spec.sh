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
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client > /dev/null
    aws s3api --profile $profile put-bucket-versioning --bucket $bucket_name-$client --versioning-configuration Status=Enabled > /dev/null
    aws --profile $profile s3 cp $file1_name  s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3 cp $file1_name  s3://$bucket_name-$client > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    When run aws --profile $profile s3 rm s3://$bucket_name-$client/$file1_name
    The output should include "delete"
      ;;
    "rclone")
    When run rclone delete $profile:$bucket_name-$client/$file1_name
    The output should include ""
      ;;
    "mgc")
    mgc profile set-current $profile > /dev/null
    When run mgc object-storage objects delete --dst $bucket_name-$client/$file1_name -f
    The output should include ""
      ;;
    esac
    The status should be success
    aws --profile $profile s3api delete-objects --bucket $bucket_name-$client --delete "$(aws --profile $profile s3api list-object-versions --bucket $bucket_name-$client| jq '{Objects: [.Versions[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')"  > /dev/null
    aws --profile $profile s3api delete-objects --bucket $bucket_name-$client --delete "$(aws --profile $profile s3api list-object-versions --bucket $bucket_name-$client| jq '{Objects: [.DeleteMarkers[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')"  > /dev/null
    aws --profile $profile s3 rb s3://$bucket_name-$client --force > /dev/null
  End
End