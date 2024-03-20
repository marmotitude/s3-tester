Describe 'Access the Private with ACL bucket with and check the list of objects:' category:"Bucket Permission"
  setup(){
    bucket_name="test-028-$(date +%s)"
    file1_name="LICENSE"
    "fake-user"
    id2="fake-user"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"028"
    profile=$1
    client=$2
    aws --profile $profile s3 mb s3://$bucket_name-$client
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-read id=$id
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
      Skip 'Teste pulado para cliente mgc'
      # When run mgc object-storage objects list $bucket_name-$client
      # The status should be success
      # The output should include "$file1_name"
      # mgc object-storage buckets delete $bucket_name-$client -f --force
      ;;
    esac
    The status should be success
    aws s3 rb s3://$bucket_name-$client --profile $profile --force
  End
End
