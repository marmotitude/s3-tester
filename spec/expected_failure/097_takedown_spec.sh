is_variable_null() {
  [[ $1 != *"-takedown"* ]]
}

Describe 'Takedown Create bucket:' category:"Bucket Permission"
  setup(){
    bucket_name="test-097-$(date +%s)"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"097"
    client=$2
    profile=$(aws configure list-profiles | grep "$1-takedown")
    Skip if "No such a "$1-takedown" user" is_variable_null "$profile"
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
      When run mgc object-storage buckets create $bucket_name-$client --raw
      The stderr should include "Blocked account"
      ;;
    esac
    The status should be failure
  End
End

Describe 'Takedown List buckets:' category:"Bucket Permission"
  setup(){
    bucket_name="test-097-$(date +%s)"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"097"
    client=$2
    profile=$(aws configure list-profiles | grep "$1-takedown")
    Skip if "No such a "$1-takedown" user" is_variable_null "$profile"
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile $profile s3api list-buckets
      The stderr should include "Blocked account"
      ;;
    "aws-s3")
      When run aws --profile $profile s3 ls
      The stderr should include "Blocked account"
      ;;
    "rclone")
      When run rclone lsd $profile: -v
      The stderr should include "Blocked account"
      ;;
    "mgc")
      mgc profile set-current $profile > /dev/null
      When run mgc object-storage buckets list --raw
      The stderr should include "Blocked account"
      ;;
    esac
    The status should be failure
  End
End

Describe 'Takedown List objects:' category:"Bucket Permission"
  setup(){
    bucket_name="test-097-$(date +%s)"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"097"
    client=$2
    profile=$(aws configure list-profiles | grep "$1-takedown")
    Skip if "No such a "$1-takedown" user" is_variable_null "$profile"
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile $profile s3api list-objects-v2 --bucket $bucket_name-$client
      The stderr should include "Blocked account"
      ;;
    "aws-s3")
      When run aws --profile $profile s3 ls s3://$bucket_name-$client
      The stderr should include "Blocked account"
      ;;
    "rclone")
      When run rclone lsd $profile:$bucket_name-$client -v
      The stderr should include "Blocked account"
      ;;
    "mgc")
      mgc profile set-current $profile > /dev/null
      When run mgc object-storage objects list $bucket_name-$client --raw
      The stderr should include "Blocked account"
      ;;
    esac
    The status should be failure
  End
End

Describe 'Takedown Delete object:' category:"Bucket Permission"
  setup(){
    bucket_name="test-097-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"097"
    client=$2
    profile=$(aws configure list-profiles | grep "$1-takedown")
    Skip if "No such a "$1-takedown" user" is_variable_null "$profile"
    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile $profile s3api delete-object --bucket $bucket_name-$client --key $file1_name
      The stderr should include "Blocked account"
      ;;
    "aws-s3")
      When run aws --profile $profile s3 rm s3://$bucket_name-$client/$file1_name
      The stderr should include "Blocked account"
      ;;
    "rclone")
      When run rclone delete $profile:$bucket_name-$client/$file1_name -v
      The stderr should include "Blocked account"
      ;;
    "mgc")
      mgc profile set-current $profile > /dev/null
      When run mgc object-storage objects delete --dst $bucket_name-$client/$file1_name --no-confirm --raw
      The stderr should include "Blocked account"
      ;;
    esac
    The status should be failure
  End
End

Describe 'Takedown Delete bucket:' category:"Bucket Permission"
  setup(){
    bucket_name="test-097-$(date +%s)"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"097"
    client=$2
    profile=$(aws configure list-profiles | grep "$1-takedown")
    Skip if "No such a "$1-takedown" user" is_variable_null "$profile"
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
      When run rclone purge $profile:$bucket_name-$client -v
      The stderr should include "Blocked account"
      ;;
    "mgc")
      mgc profile set-current $profile > /dev/null
      When run mgc object-storage buckets delete $bucket_name-$client --no-confirm --raw
      The stderr should include "Blocked account"
      ;;
    esac
    The status should be failure
  End
End
