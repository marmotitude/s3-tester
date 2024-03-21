is_variable_null() {
  [ -z "$1" ]
}

Describe 'Set a presigned URL for a private with ACL bucket:' category:"Bucket Sharing"
  setup(){
    bucket_name="test-037-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"037"
    profile=$1
    client=$2
    id=$(aws s3api --profile $profile-second list-buckets | jq -r '.Owner.ID')
    echo $id
    Skip if "A variável id é nula" is_variable_null "$id"
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")    
    aws --profile $profile s3 mb s3://$bucket_name-$client
    aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-write id=$id --grant-read id=$id
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client
    When run aws --profile $profile s3 presign s3://$bucket_name-$client/$file1_name
    The status should be success
    The output should include X-Amz-Algorithm
    aws --profile $profile s3 rb s3://$bucket_name-$client --force
      ;;
    "rclone")
      Skip 'Teste pulado para cliente rclone'
      ;;
    "mgc")
      Skip 'Teste pulado para cliente mgc'
      ;;
    esac
  End
End
