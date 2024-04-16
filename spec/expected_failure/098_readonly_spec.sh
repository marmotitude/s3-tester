Describe 'Read-only Create bucket:' category:"Bucket Permission"
  setup(){
    bucket_name="test-098-$(date +%s)"
  }
  Before 'setup' 
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"098"
    profile=$1
    client=$2
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile $profile s3api create-bucket --bucket $bucket_name-$client
      The stderr should include "Blocked account"
      ;;
    "aws-s3")
      When run aws --profile $profile s3 mb s3://$bucket_name-$client
      The stderr should include "Blocked account"
      ;;
    "rclone")
      When run rclone mkdir $profile:$bucket_name-$client -v
      The stderr should include "Blocked account"
      ;;
    "mgc")
      mgc profile set-current $profile > /dev/null
      When run mgc object-storage buckets create $bucket_name-$client
      The stderr should include "Blocked account"
      ;;
    esac
    The status should be failure
  End
End

Describe 'Read-only List buckets:' category:"Bucket Permission"
  setup(){
    bucket_name="test-098-$(date +%s)"
  }
  Before 'setup' 
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"098"
    profile=$1
    client=$2
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile $profile s3api list-buckets
      The stdout should include Buckets
      ;;
    "aws-s3")
      When run aws --profile $profile s3 ls
      The stdout should include ""
      ;;
    "rclone")
      When run rclone lsd $profile: -v
      The stdout should include ""
      ;;
    "mgc")
      mgc profile set-current $profile > /dev/null
      When run mgc object-storage buckets list 
      The stdout should include BUCKETS
      ;;
    esac
    The status should be success
  End
End

Describe 'Read-only List objects:' category:"Bucket Permission"
  setup(){
    bucket_name="test-098-$(date +%s)"
  }
  Before 'setup' 
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"098"
    profile=$1
    client=$2
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile $profile s3api list-objects-v2 --bucket test-test #$bucket_name-$client
      The stdout should include RequestCharged
      ;;
    "aws-s3")
      When run aws --profile $profile s3 ls s3://test-test #$bucket_name-$client
      ;;
    "rclone")
      When run rclone lsd $profile:test-test -v #$bucket_name-$client -v
      ;;
    "mgc")
      mgc profile set-current $profile > /dev/null
      When run mgc object-storage objects list test-test #$bucket_name-$client
      The stdout should include FILES
      ;;
    esac
    The status should be success
  End
End

Describe 'Read-only Delete object:' category:"Bucket Permission"
  setup(){
    bucket_name="test-098-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup' 
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"098"
    profile=$1
    client=$2
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile $profile s3api delete-object --bucket $bucket_name-$client --key $file1_name
      The stderr should include "Blocked account"
    The status should be failure
      ;;
    "aws-s3")
      When run aws --profile $profile s3 rm s3://test-test/$file1_name
      The stderr should include "Blocked account"
      The status should be failure
      ;;
    "rclone")
      When run rclone delete $profile:test-test/$file1_name -v
      The stderr should include ""
      The status should be success
      ;;
    "mgc")
      mgc profile set-current $profile > /dev/null
      When run mgc object-storage objects delete --dst $bucket_name-$client/$file1_name -f
      The stderr should include "Blocked account"
    The status should be failure
      ;;
    esac
  End
End

Describe 'Read-only Delete bucket:' category:"Bucket Permission"
  setup(){
    bucket_name="test-098-$(date +%s)"
  }
  Before 'setup' 
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"098"
    profile=$1
    client=$2
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile $profile s3api delete-bucket --bucket $bucket_name-$client 
      The stderr should include "Blocked account"
      ;;
    "aws-s3")
      When run aws --profile $profile s3 rb s3://$bucket_name-$client
      The stderr should include "Blocked account"
      ;;
    "rclone")
      When run rclone purge $profile:test-test -v
      The stderr should include "Blocked account"
      ;;
    "mgc")
      mgc profile set-current $profile > /dev/null
      When run mgc object-storage buckets delete $bucket_name-$client -f
      The stderr should include "Blocked account"
      ;;
    esac
    The status should be failure
  End
End