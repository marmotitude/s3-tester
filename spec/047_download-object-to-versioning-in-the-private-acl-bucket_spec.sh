is_variable_null() {
  [ -z "$1" ]
}

Describe 'Download object to versioning in the private ACL bucket:' category:"Object Versioning"
  setup(){
    bucket_name="test-047-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"047"
    profile=$1
    client=$2
    id=$(aws s3api --profile $profile-second list-buckets | jq -r '.Owner.ID')
    Skip if "No such a "$profile-second" user" is_variable_null "$id"
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client > /dev/null
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-write id=$id --grant-read id=$id > /dev/null
    aws s3api --profile $profile put-bucket-versioning --bucket $bucket_name-$client --versioning-configuration Status=Enabled > /dev/null
    aws --profile $profile s3 cp $file1_name  s3://$bucket_name-$client > /dev/null
    aws s3api --profile $profile put-object-acl --bucket $bucket_name-$client --key $file1_name --grant-write id=$id --grant-read id=$id > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    When run aws --profile $profile-second s3 cp s3://$bucket_name-$client/$file1_name $file1_name-2
    The status should be success
    The output should include "$file1_name"
      ;;
    "rclone")
    When run rclone copy $profile-second:$bucket_name-$client/$file1_name $file1_name-2
    The status should be success
    The output should include ""
      ;;
    "mgc")
    Skip "Skipped test to $client"
      ;;
    esac
    aws --profile $profile s3api delete-objects --bucket $bucket_name-$client --delete "$(aws --profile $profile s3api list-object-versions --bucket $bucket_name-$client| jq '{Objects: [.Versions[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')"  > /dev/null
    aws --profile $profile s3 rb s3://$bucket_name-$client --force > /dev/null
    rm -rf $file1_name-2
  End
End