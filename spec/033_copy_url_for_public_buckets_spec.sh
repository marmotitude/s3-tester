Describe 'Copy URL for public buckets:' category:"Bucket Permission"
  setup(){
    bucket_name="test-033-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"033"
    profile=$1
    client=$2
    case "$client" in
    "aws" | "aws-s3")
    Skip "Skipped test to $client"
      ;;
    "aws-s3api")
    Skip "Skipped test to $client"
      ;;
    "rclone")
    Skip "Skipped test to $client"
      ;;
    "mgc")
      mgc profile set $profile > /dev/null
      When run bash ./spec/retry_command.sh "mgc object-storage buckets public-url --dst $bucket_name-$client --raw"
      # When run mgc object-storage buckets public-url --dst $bucket_name-$client --raw
      The output should include "$bucket_name-$client"
      ;;
    esac
    The status should be success
  End
End
