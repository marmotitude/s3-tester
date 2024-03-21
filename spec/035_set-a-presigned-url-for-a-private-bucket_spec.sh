Describe 'Set a presigned URL for a private bucket:' category:"Bucket Sharing"
  setup(){
    bucket_name="test-035-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"035"
    profile=$1-second
    client=$2
    aws --profile $profile s3 mb s3://$bucket_name-$client
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    When run aws --profile $profile s3 presign s3://$bucket_name-$client/$file1_name
    The status should be success
    The output should include X-Amz-Algorithm
      ;;
    "rclone")
      Skip 'Teste pulado para cliente rclone'
      ;;
    "mgc")
      Skip 'Teste pulado para cliente mgc'
      ;;
    esac
    aws s3 rb s3://$bucket_name-$client --profile $profile --force
  End
End
