Include ./spec/019_utils.sh
Describe 'Download object to versioning in the public bucket:' category:"ObjectVersioning"
  setup(){
    bucket_name="test-045-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"045"
    profile=$1
    client=$2
    test_bucket_name="$bucket_name-$client-$profile"
    printf "\n$test_bucket_name" >> ./report/buckets_to_delete.txt
    aws --profile $profile s3api create-bucket --bucket $test_bucket_name  --acl public-read > /dev/null
    aws s3api --profile $profile put-bucket-versioning --bucket $test_bucket_name --versioning-configuration Status=Enabled > /dev/null
    aws --profile $profile s3 cp $file1_name  s3://$test_bucket_name > /dev/null
    aws --profile $profile s3 cp $file1_name  s3://$test_bucket_name > /dev/null
    aws --profile $profile s3 cp $file1_name  s3://$test_bucket_name > /dev/null
    wait_command object-exists $profile "$test_bucket_name" "$file1_name"
    version=$(aws s3api list-object-versions --bucket $test_bucket_name --profile $profile | jq -r '.Versions[1].VersionId')
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    When run aws --profile $profile-second s3api get-object --bucket $test_bucket_name --key $file1_name $file1_name-2
    The status should be failure
    The stderr should include "AccessDenied"
      ;;
    "rclone")
    Skip "Skipped test to $client"
      ;;
    "mgc")
    mgc workspace set $profile-second > /dev/null
    When run bash ./spec/retry_command.sh "mgc object-storage objects download --src $test_bucket_name/$file1_name --obj-version $version --dst ./$file1_name-2 --raw"
    # When run mgc object-storage objects download --src $test_bucket_name/$file1_name --obj-version $version --dst ./$file1_name-2 --raw
    The status should be failure
    #The stderr should include "403"
    The output should include "403"
      ;;
    esac
    aws --profile $profile s3api delete-objects --bucket $test_bucket_name --delete "$(aws --profile $profile s3api list-object-versions --bucket $test_bucket_name| jq '{Objects: [.Versions[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')"  > /dev/null
    rclone purge --log-file /dev/null "$profile:$test_bucket_name" > /dev/null
  End
End
