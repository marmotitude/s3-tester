Describe 'Upload object to versioning in the public bucket:' category:"Object Versioning"
  setup(){
    bucket_name="test-042-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"042"
    profile=$1
    client=$2
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client --acl public-read  > /dev/null
    aws s3api --profile $profile put-bucket-versioning --bucket $bucket_name-$client --versioning-configuration Status=Enabled > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    When run aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client
    The status should be success
    The output should include "$file1_name"
      ;;
    "rclone")
    When run rclone copy $file1_name $profile:$bucket_name-$client
    The status should be success
    The output should include ""
      ;;
    "mgc")
    mgc profile set-current $profile > /dev/null
    When run mgc object-storage objects upload --src $file1_name --dst $bucket_name-$client --raw
    The status should be success
    The output should include ""
      ;;
    esac
    aws --profile $profile s3api delete-objects --bucket $bucket_name-$client --delete "$(aws --profile $profile s3api list-object-versions --bucket $bucket_name-$client| jq '{Objects: [.Versions[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')"  > /dev/null
    aws --profile $profile s3 rb s3://$bucket_name-$client --force > /dev/null
  End
End
