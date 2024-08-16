Include ./spec/019_utils.sh
is_variable_null() {
  [ -z "$1" ]
}

Describe 'Access the Private with ACL bucket with and check the list of objects:' category:"Bucket Permission"
  setup(){
    bucket_name="test-024-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"024"
    profile=$1
    client=$2
    id=$(aws s3api --profile $profile-second list-buckets | jq -r '.Owner.ID')
    Skip if "No such a "$profile-second" user" is_variable_null "$id"
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    # wait_command bucket-exists $profile "$bucket_name-$client"
    #aws --profile $profile s3api wait bucket-exists --bucket $bucket_name-$client
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client > /dev/null
    # wait_command object-exists $profile "$bucket_name-$client" "$file1_name"
    #aws --profile $profile s3api wait object-exists --key $file1_name --bucket $bucket_name-$client
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-read id=$id > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    # wait_command bucket-exists $profile "$bucket_name-$client" 
    When run bash ./spec/retry_command.sh "aws --profile $profile-second s3api list-objects-v2 --bucket $bucket_name-$client"
    # When run aws --profile $profile-second s3api list-objects-v2 --bucket $bucket_name-$client
    The output should include "$file1_name"
      ;;
    "rclone")
    # wait_command bucket-exists $profile "$bucket_name-$client"
    When run bash ./spec/retry_command.sh "rclone ls $profile-second:$bucket_name-$client"
    # When run rclone ls $profile-second:$bucket_name-$client
    The output should include "$file1_name"
      ;;
    "mgc")
      # wait_command bucket-exists $profile "$bucket_name-$client"
      #aws --profile $profile-second s3api wait bucket-exists --bucket $bucket_name-$client
      mgc profile set $profile-second > /dev/null
      #Skip "Skipped test to $client"
      When run bash ./spec/retry_command.sh "mgc object-storage objects list --dst $bucket_name-$client --raw"
      #When run mgc object-storage objects list --dst $bucket_name-$client --raw
      The output should include $file1_name
      ;;
    esac
    The status should be success
    rclone purge --log-file /dev/null "$profile:$bucket_name-$client" > /dev/null
    # wait_command bucket-not-exists $profile "$bucket_name-$client"
    #aws s3api wait bucket-not-exists --bucket $bucket_name-$client --profile $profile
  End
End
