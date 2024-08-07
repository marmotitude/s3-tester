Describe 'Delete bucket with objects with versions:' category:"Object Versioning"
  setup(){
    bucket_name="test-050-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"050"
    profile=$1
    client=$2
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client > /dev/null
    aws s3api --profile $profile put-bucket-versioning --bucket $bucket_name-$client --versioning-configuration Status=Enabled > /dev/null
    aws --profile $profile s3 cp $file1_name  s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3 cp $file1_name  s3://$bucket_name-$client > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    When run aws --profile $profile s3 rb s3://$bucket_name-$client
    The status should be failure
    The stderr should include BucketNotEmpty
    aws --profile $profile s3api delete-objects --bucket $bucket_name-$client --delete "$(aws --profile $profile s3api list-object-versions --bucket $bucket_name-$client| jq '{Objects: [.Versions[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')" > /dev/null
    rclone purge --log-file /dev/null "$profile:$bucket_name-$client" > /dev/null
      ;;
    "rclone")
    When run rclone rmdir $profile:$bucket_name-$client
    The status should be failure
    The stderr should include BucketNotEmpty
    aws --profile $profile s3api delete-objects --bucket $bucket_name-$client --delete "$(aws --profile $profile s3api list-object-versions --bucket $bucket_name-$client| jq '{Objects: [.Versions[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')" > /dev/null
    #aws --profile $profile s3api delete-objects --bucket $bucket_name-$client --delete "$(aws --profile $profile s3api list-object-versions --bucket $bucket_name-$client| jq '{Objects: [.DeleteMarkers[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')" | jq
    rclone purge --log-file /dev/null "$profile:$bucket_name-$client" > /dev/null
      ;;
    "mgc")
    mgc profile set $profile > /dev/null
    When run mgc object-storage buckets delete $bucket_name-$client --no-confirm --recursive --raw
    The status should be failure
    The stderr should include "bucket contains multiple versions of objects"
    aws --profile $profile s3api delete-objects --bucket $bucket_name-$client --delete "$(aws --profile $profile s3api list-object-versions --bucket $bucket_name-$client| jq '{Objects: [.Versions[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')" > /dev/null
    aws --profile $profile s3api delete-objects --bucket $bucket_name-$client --delete "$(aws --profile $profile s3api list-object-versions --bucket $bucket_name-$client| jq '{Objects: [.DeleteMarkers[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')" > /dev/null
    rclone purge --log-file /dev/null "$profile:$bucket_name-$client" > /dev/null
      ;;
    esac
  End
End
