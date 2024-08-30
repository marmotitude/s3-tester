Include ./spec/019_utils.sh
is_variable_null() {
  [ -z "$1" ]
}

Describe 'Set bucket label:' category:"Bucket Management"
  setup(){
    bucket_name="test-101-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup' 
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"101"
    profile=$1
    client=$2
    label='marketing'
    mgc workspace set $profile > /dev/null
    mgc object-storage buckets create $bucket_name-$client
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      Skip "Skipped test to $client"
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      When run mgc object-storage buckets label set --bucket $bucket_name-$client --label $label
      The stdout should include ""
      The status should be success
      ;;
    esac
    #rclone purge $profile:$bucket_name-$client > /dev/null
  End
End

Describe 'Get bucket label:' category:"Bucket Management"
  setup(){
    bucket_name="test-101-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup' 
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"101"
    profile=$1
    client=$2
    label='marketing'
    mgc workspace set $profile > /dev/null
    mgc object-storage buckets create $bucket_name-$client
    mgc object-storage buckets label set --bucket $bucket_name-$client --label $label
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      Skip "Skipped test to $client"
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      When run mgc object-storage buckets label get --bucket $bucket_name-$client
      The stdout should include "marketing"
      The status should be success
      ;;
    esac
    #rclone purge $profile:$bucket_name-$client > /dev/null
  End
End

Describe 'Delete bucket label:' category:"Bucket Management"
  setup(){
    bucket_name="test-101-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup' 
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"101"
    profile=$1
    client=$2
    label_delete='to-delete'
    labels="marketing,${label_delete}"
    mgc workspace set $profile > /dev/null
    mgc object-storage buckets create $bucket_name-$client
    mgc object-storage buckets label set --bucket $bucket_name-$client --label $labels
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      Skip "Skipped test to $client"
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      mgc object-storage buckets label delete --bucket $bucket_name-$client --label $label_delete
      When run mgc object-storage buckets label get --bucket $bucket_name-$client
      The stdout should include "marketing"
      The stdout should not include $label_delete
      The status should be success
      ;;
    esac
    #rclone purge $profile:$bucket_name-$client > /dev/null
  End
End

