Describe 'Download object to versioning in the private bucket:' category:"Object Versioning"
  setup(){
    bucket_name="test-046-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"046"
    profile=$1
    client=$2
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client > /dev/null
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-write id=$id --grant-read id=$id > /dev/null
    aws s3api --profile $profile put-bucket-versioning --bucket $bucket_name-$client --versioning-configuration Status=Enabled > /dev/null
    aws --profile $profile s3 cp $file1_name  s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3 cp $file1_name  s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3 cp $file1_name  s3://$bucket_name-$client > /dev/null
    sleep 10
    version=$(aws s3api list-object-versions --bucket $bucket_name-$client --profile $profile | jq -r '.Versions[1].VersionId')
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
   When run bash ./spec/retry_command.sh "aws --profile $profile s3api get-object --bucket $bucket_name-$client --key $file1_name --version-id $version $file1_name-2"
    The status should be success
    The output should include "ETag"
      ;;
    "rclone")
    Skip "Skipped test to $client"
      ;;
    "mgc")
    mgc workspace set $profile > /dev/null
    When run bash ./spec/retry_command.sh "mgc object-storage objects download --src $bucket_name-$client/$file1_name --obj-version $version --dst ./$file1_name-2 --raw"
    # When run mgc object-storage objects download --src $bucket_name-$client/$file1_name --obj-version $version --dst ./$file1_name-2 --raw
    The status should be success
    The output should include "LICENSE"
      ;;
    esac
    aws --profile $profile s3api delete-objects --bucket $bucket_name-$client --delete "$(aws --profile $profile s3api list-object-versions --bucket $bucket_name-$client| jq '{Objects: [.Versions[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')"  > /dev/null
    rclone purge --log-file /dev/null "$profile:$bucket_name-$client" > /dev/null
    rm -rf $file1_name-2  > /dev/null
  End
End
