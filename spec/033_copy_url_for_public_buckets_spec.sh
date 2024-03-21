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
    Skip 'Teste pulado para cliente aws'
      ;;
    "aws-s3api")
    Skip 'Teste pulado para cliente aws-s3api'
      ;;
    "rclone")
    Skip 'Teste pulado para cliente rclone'
      ;;
    "mgc")
      When run mgc object-storage buckets public-url --dst $bucket_name-$client
      The output should include "$bucket_name-$client"
      ;;
    esac
    The status should be success
  End
End
