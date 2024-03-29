Describe 'Access the public bucket and check the list of objects:' category:"Bucket Permission"
  setup(){
    bucket_name="test-019-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup' 
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"019"
    profile=$1
    client=$2
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client --acl public-read > /dev/null
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile-second s3api list-objects-v2 --bucket $bucket_name-$client
      The output should include "$file1_name"
      ;;
    "rclone")
      When run rclone ls $profile-second:$bucket_name-$client
      The output should include "$file1_name"
      ;;
    "mgc")
      mgc profile set-current $profile-second > /dev/null
      When run mgc object-storage objects list --dst $bucket_name-$client
      The output should include "$file1_name"
      ;;
    esac
    The status should be success
    aws s3 rb s3://$bucket_name-$client --profile $profile --force > /dev/null
  End
End