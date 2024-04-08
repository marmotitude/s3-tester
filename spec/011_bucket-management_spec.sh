
delete_bucket() {
  profile=$1
  client=$2
  bucket_name="$3"

  aws --profile "$profile" s3 rb --force "s3://$bucket_name" > /dev/null
}

Describe 'List buckets' category:"Bucket Management" id:"011"
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End

  PREFIX="s3-tester-$(openssl rand -hex 10 | tr -dc 'a-z0-9' | head -c 10)"
  bucket_name="$PREFIX-foo"

  Example "on profile $1 using client $2"
    profile=$1
    client=$2

    # Create sample bucket to validate listing
    aws --profile "$profile" s3api create-bucket --bucket "$bucket_name"> /dev/null

    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile "$profile" s3api list-buckets
      The output should include "\"Name\": \"$bucket_name\""
      ;;
    "aws-s3")
      When run aws --profile "$profile" s3 ls "s3://"
      The output should include "$bucket_name"
      ;;
    "mgc")
      When run mgc object-storage buckets list
      The output should include "$bucket_name"
      ;;
    "rclone")
      When run rclone lsd "$profile:"
      The output should include "$bucket_name"
      ;;
    esac
    The status should be success
    Assert delete_bucket "$1" "$2" "$bucket_name"
  End
End


Describe 'Delete buckets' category:"Bucket Management"
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End

  PREFIX="s3-tester-$(openssl rand -hex 10 | tr -dc 'a-z0-9' | head -c 10)"
  bucket_name="$PREFIX-foo"
  Example "delete empty bucket $bucket_name on profile $1 using client $2" id:"015"
    profile=$1
    client=$2

    # Create sample bucket to validate deleting
    aws --profile "$profile" s3api create-bucket --bucket "$bucket_name" > /dev/null

    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile "$profile" s3api delete-bucket --bucket "$bucket_name"
      The output should equal ""
      ;;
    "aws-s3")
      When run aws --profile "$profile" s3 rb "s3://$bucket_name"
      The output should equal "remove_bucket: $bucket_name"
      ;;
    "mgc")
      Skip "Dificil testar por precisar fazer input com o nome do bucket"
      ;;
      # When run mgc object-storage buckets delete
      # The output should include "$bucket_name"
      # ;;
    "rclone")
      When run rclone rmdir "$profile:$bucket_name" -v
      The error should include "Bucket \"$bucket_name\" deleted"
      ;;
    esac
    The status should be success
  End

  Example "delete bucket with data $bucket_name on profile $1 using client $2" id:"016"
    profile=$1
    client=$2

    # Create sample bucket to validate deleting
    aws --profile "$profile" s3api create-bucket --bucket "$bucket_name" > /dev/null
    aws --profile "$profile" s3api put-object --bucket "$bucket_name" --key foo --body README.md> /dev/null

    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile "$profile" s3api delete-bucket --bucket "$bucket_name"
      # This bucket is not deletable using s3api, since the objects should be removed first
      The error should include "BucketNotEmpty"
      The status should be failure
      Assert delete_bucket "$1" "$2" "$bucket_name"
      ;;
    "aws-s3")
      When run aws --profile "$profile" s3 rb "s3://$bucket_name" --force
      The output should include "remove_bucket: $bucket_name"
      The status should be success
      ;;
    "mgc")
      Skip "Dificil testar por precisar fazer input com o nome do bucket"
      ;;
      # When run mgc object-storage buckets delete
      # The output should include "$bucket_name"
      # ;;
    "rclone")
      When run rclone purge "$profile:$bucket_name" -v
      The error should include "Bucket \"$bucket_name\" deleted"
      The status should be success
      ;;
    esac
  End
End


