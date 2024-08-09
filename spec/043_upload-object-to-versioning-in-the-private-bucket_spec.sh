Describe 'Upload object to versioning in the private bucket:' category:"Object Versioning"
  setup(){
    bucket_name="test-043-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"043"
    profile=$1
    client=$2
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client  > /dev/null
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
    mgc profile set $profile > /dev/null
    #Skip "Skipped test to $client"
    When run mgc object-storage objects upload --src $file1_name --dst $bucket_name-$client --raw
    The status should be success
    The output should include ""
      ;;
    esac
    #aws --profile $profile s3api delete-objects --bucket $bucket_name-$client --delete "$(aws --profile $profile s3api list-object-versions --bucket $bucket_name-$client| jq '{Objects: [.Versions[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')"  > /dev/null
    rclone purge --log-file /dev/null "$profile:$bucket_name-$client" > /dev/null
  End
End
