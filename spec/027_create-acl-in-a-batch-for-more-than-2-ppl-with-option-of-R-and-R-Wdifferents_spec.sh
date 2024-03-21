is_variable_null() {
  [ -z "$1" ]
}


Describe 'Create ACL in a batch for more than 2 ppl with option of R and R/W differents:' category:"Bucket Permission"
  setup(){
    bucket_name="test-027-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"027"
    profile=$1
    client=$2
    id=$(aws s3api --profile $profile-second list-buckets | jq -r '.Owner.ID')
    id2=$id
    Skip if "A variável id é nula" is_variable_null "$id"
    aws --profile $profile s3 mb s3://$bucket_name-$client
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    When run aws s3api --profile $profile put-bucket-acl --bucket $bucket_name-$client --grant-write id=$id --grant-read id=$id2
    The output should include ""
      ;;
    "rclone")
    Skip 'Teste pulado para cliente rclone'
      ;;
    "mgc")
      When run mgc object-storage buckets acl set --grant-read id=$id --grant-write id=$id --bucket $bucket_name-$client
      The output should include ""
      ;;
    esac
    The status should be success
    aws s3 rb s3://$bucket_name-$client --profile $profile --force
  End
End
