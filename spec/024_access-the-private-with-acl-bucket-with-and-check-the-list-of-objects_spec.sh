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
    id="fake-user"
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    aws --profile $profile s3 mb s3://$bucket_name-$client
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-read id=$id
    When run aws --profile $profile-second s3api list-objects-v2 --bucket $bucket_name-$client
    The status should be success
    The output should include "$file1_name"
    aws s3 rb s3://$bucket_name-$client --profile $profile --force
      ;;
    "rclone")
    aws --profile $profile s3 mb s3://$bucket_name-$client
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-read id=$id
    When run rclone ls $profile-second:$bucket_name-$client
    The status should be success
    The output should include "$file1_name"
    aws s3 rb s3://$bucket_name-$client --profile $profile --force
      ;;
    "mgc")
      Skip 'Teste pulado para cliente mgc'
      # mgc object-storage buckets create $bucket_name-$client
      # mgc object-storage buckets acl set --grant-read id=$id --bucket $bucket_name-$client
      # mgc object-storage objects upload --src $file1_name --dst $bucket_name-$client
      # When run mgc object-storage objects list --dst $bucket_name-$client
      # The status should be success
      # The output should include $file1_name
      # mgc object-storage buckets delete $bucket_name-$client -f --force
      ;;
    esac
  End
End
