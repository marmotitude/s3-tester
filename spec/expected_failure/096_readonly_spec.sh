is_variable_null() {
  [[ $1 != *"-readonly"* ]]
}

Describe 'Read-only Create bucket:' category:"BucketPermission"
  setup(){
    bucket_name="test-096-$(date +%s)"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"096"
    client=$2
    profile=$(aws configure list-profiles | grep "$1-readonly")
    test_bucket_name="$bucket_name-$client-$profile"
    printf "\n$test_bucket_name" >> ./report/buckets_to_delete.txt
    Skip if "No such a "$1-readonly" user" is_variable_null "$profile"
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile $profile s3api create-bucket --bucket $test_bucket_name
      The stderr should include "Blocked account"
      ;;
    "aws-s3")
      When run aws --profile $profile s3 mb s3://$test_bucket_name
      The stderr should include "Blocked account"
      ;;
    "rclone")
      When run rclone mkdir $profile:$test_bucket_name -v
      The stderr should include "Blocked account"
      ;;
    "mgc")
      mgc workspace set $profile > /dev/null
      When run mgc object-storage buckets create $test_bucket_name --raw
      The stderr should include "Blocked account"
      ;;
    esac
    The status should be failure
  End
End

Describe 'Read-only List buckets:' category:"BucketPermission"
  setup(){
    bucket_name="test-096-$(date +%s)"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"096"
    client=$2
    profile=$(aws configure list-profiles | grep "$1-readonly")
    test_bucket_name="$bucket_name-$client-$profile"
    printf "\n$test_bucket_name" >> ./report/buckets_to_delete.txt
    Skip if "No such a "$1-readonly" user" is_variable_null "$profile"
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
      mgc workspace set $profile > /dev/null
      When run mgc object-storage buckets list --raw
      The stdout should include BUCKETS
      ;;
    esac
    The status should be success
  End
End

Describe 'Read-only List objects:' category:"BucketPermission"
  setup(){
    bucket_name="test-096-$(date +%s)"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"096"
    client=$2
    profile=$(aws configure list-profiles | grep "$1-readonly")
    test_bucket_name="$bucket_name-$client-$profile"
    printf "\n$test_bucket_name" >> ./report/buckets_to_delete.txt
    Skip if "No such a "$1-readonly" user" is_variable_null "$profile"
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile $profile s3api list-objects-v2 --bucket test-test #$test_bucket_name
      The stdout should include RequestCharged
      ;;
    "aws-s3")
      When run aws --profile $profile s3 ls s3://test-test #$test_bucket_name
      ;;
    "rclone")
      When run rclone lsd $profile:test-test -v #$test_bucket_name -v
      ;;
    "mgc")
      mgc workspace set $profile > /dev/null
      When run mgc object-storage objects list test-test --raw #$test_bucket_name
      The stdout should include FILES
      ;;
    esac
    The status should be success
  End
End

Describe 'Read-only Delete object:' category:"BucketPermission"
  setup(){
    bucket_name="test-096-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"096"
    client=$2
    profile=$(aws configure list-profiles | grep "$1-readonly")
    test_bucket_name="$bucket_name-$client-$profile"
    printf "\n$test_bucket_name" >> ./report/buckets_to_delete.txt
    Skip if "No such a "$1-readonly" user" is_variable_null "$profile"
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile $profile s3api delete-object --bucket $test_bucket_name --key $file1_name
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
      mgc workspace set $profile > /dev/null
      When run mgc object-storage objects delete --dst $test_bucket_name/$file1_name --no-confirm --raw
      The stderr should include "Blocked account"
    The status should be failure
      ;;
    esac
  End
End

Describe 'Read-only Delete bucket:' category:"BucketPermission"
  setup(){
    bucket_name="test-096-$(date +%s)"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"096"
    client=$2
    profile=$(aws configure list-profiles | grep "$1-readonly")
    test_bucket_name="$bucket_name-$client-$profile"
    printf "\n$test_bucket_name" >> ./report/buckets_to_delete.txt
    Skip if "No such a "$1-readonly" user" is_variable_null "$profile"
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile $profile s3api delete-bucket --bucket $test_bucket_name
      The stderr should include "Blocked account"
      ;;
    "aws-s3")
      When run aws --profile $profile s3 rb s3://$test_bucket_name
      The stderr should include "Blocked account"
      ;;
    "rclone")
      When run rclone purge $profile:test-test -v
      The stderr should include "Blocked account"
      ;;
    "mgc")
      mgc workspace set $profile > /dev/null
      When run mgc object-storage buckets delete $test_bucket_name --no-confirm --raw
      The stderr should include "Blocked account"
      ;;
    esac
    The status should be failure
  End
End
