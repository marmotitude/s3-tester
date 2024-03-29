
delete_bucket() {
  profile=$1
  client=$2
  bucket_name="$3"

  aws --profile "$profile" s3api delete-bucket --bucket "$bucket_name" > /dev/null
}

check_length() {
    local str=$1
    if [[ ${#str} -le 2 || ${#str} -eq 64 ]]; then
        return 0  # True
    else
        return 1  # False
    fi
}

Describe 'Create bucket' category:"Bucket Management"
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End

  bucket_name="foo bar"
  Describe "with INVALID name with spaces $bucket_name"  id:"002"
    Example "on profile $1 using client $2"
      profile=$1
      client=$2

      case "$client" in
      "aws-s3api" | "aws")
        When run aws --profile "$profile" s3api create-bucket --bucket "$bucket_name"
        The error should include 'Invalid bucket name "foo bar"'
        ;;
      "aws-s3")
        When run aws --profile "$profile" s3 mb "s3://$bucket_name"
        The error should include "make_bucket failed: s3://foo bar Parameter validation failed"
        ;;
      "mgc")
        When run mgc object-storage buckets create "$bucket_name"
        The error should include "InvalidBucketName"
        ;;
      "rclone")
        When run rclone mkdir "$profile:$bucket_name" -v
        The error should include "Failed to mkdir"
        ;;
      esac
      The status should be failure
    End
  End

  bucket_name="$(openssl rand -hex 40 | tr -dc '[:lower:]' | head -c 40)"
  Describe "with VALID name with only lowercase letters $bucket_name"  id:005
    Example "on profile $1 using client $2"
      profile=$1
      client=$2

      case "$client" in
      "aws-s3api" | "aws")
        When run aws --profile "$profile" s3api create-bucket --bucket "$bucket_name"
        The output should include "\"Location\": \"/$bucket_name\""
        ;;
      "aws-s3")
        When run aws --profile "$profile" s3 mb "s3://$bucket_name"
        The output should include "make_bucket: $bucket_name"
        ;;
      "mgc")
        When run mgc object-storage buckets create "$bucket_name"
        The output should include "Created bucket $bucket_name"
        ;;
      "rclone")
        When run rclone mkdir "$profile:$bucket_name" -v
        The error should include "Bucket \"$bucket_name\" created"
        ;;
      esac
      The status should be success
      Assert delete_bucket "$1" "$2" "$bucket_name"
    End
  End

  bucket_name="$(openssl rand -hex 40 | tr -dc '0-9' | head -c 40)"
  Describe "with VALID name with only numbers $bucket_name"  id:006
    Example "on profile $1 using client $2"
      profile=$1
      client=$2

      case "$client" in
      "aws-s3api" | "aws")
        When run aws --profile "$profile" s3api create-bucket --bucket "$bucket_name"
        The output should include "\"Location\": \"/$bucket_name\""
        ;;
      "aws-s3")
        When run aws --profile "$profile" s3 mb "s3://$bucket_name"
        The output should include "make_bucket: $bucket_name"
        ;;
      "mgc")
        When run mgc object-storage buckets create "$bucket_name"
        The output should include "Created bucket $bucket_name"
        ;;
      "rclone")
        When run rclone mkdir "$profile:$bucket_name" -v
        The error should include "Bucket \"$bucket_name\" created"
        ;;
      esac
      The status should be success
      Assert delete_bucket "$1" "$2" "$bucket_name"
    End
  End

  PREFIX="s3-tester-$(openssl rand -hex 10 | tr -dc 'a-z0-9' | head -c 10)"
  bucket_name="$PREFIX-foo"
  Describe "with VALID name $bucket_name" id:008
    Example "on profile $1 using client $2"
      profile=$1
      client=$2

      case "$client" in
      "aws-s3api" | "aws")
        When run aws --profile "$profile" s3api create-bucket --bucket "$bucket_name"
        The output should include "\"Location\": \"/$bucket_name\""
        ;;
      "aws-s3")
        When run aws --profile "$profile" s3 mb "s3://$bucket_name"
        The output should include "make_bucket: $bucket_name"
        ;;
      "mgc")
        When run mgc object-storage buckets create "$bucket_name"
        The output should include "Created bucket $bucket_name"
        ;;
      "rclone")
        When run rclone mkdir "$profile:$bucket_name" -v
        The error should include "Bucket \"$bucket_name\" created"
        ;;
      esac
      The status should be success
      Assert delete_bucket "$1" "$2" "$bucket_name"
    End
  End
End


Describe 'Create bucket with invalid names' category:"Bucket Management"
  Parameters:matrix
    $PROFILES
    $CLIENTS
    Foobar FOOBAR a ab ebabdabbffceecbacbcbfdccdaaaedfcebbbeffeceeddfadbaccaabdfzqwertq
  End

  Example "on profile $1 using client $2 with invalid name $3"
    profile=$1
    client=$2
    bucket_name=$3

    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile "$profile" s3api create-bucket --bucket "$bucket_name"
      The error should include 'An error occurred (InvalidBucketName) when calling the CreateBucket operation'
      ;;
    "aws-s3")
      When run aws --profile "$profile" s3 mb "s3://$bucket_name"
      The error should include "make_bucket failed: s3://$bucket_name An error occurred (InvalidBucketName)"
      ;;
    "mgc")
      Skip if "mgc cli está validando tamanho do nome" check_length "$bucket_name"
      When run mgc object-storage buckets create "$bucket_name"
      The error should include "InvalidBucketName"
      ;;
    "rclone")
      When run rclone mkdir "$profile:$bucket_name" -v
      The error should include "Failed to mkdir"
      ;;
    esac
    The status should be failure
  End
End


%const INVALID_CHARS: "% @ | \\ [ ^ ] { } | &"
Describe 'Create bucket with invalid characters' category:"Bucket Management" id:007
  Parameters:matrix
    $PROFILES
    $CLIENTS
    $INVALID_CHARS
  End

  Example "on profile $1 using client $2 with invalid character $3"
    profile=$1
    client=$2
    bucket_name="foo$3bar"

    case "$client" in
    "aws-s3api" | "aws")
      When run aws --profile "$profile" s3api create-bucket --bucket "$bucket_name"
      The error should include "Bucket name must match the regex"
      ;;
    "aws-s3")
      When run aws --profile "$profile" s3 mb "s3://$bucket_name"
      The error should include "Bucket name must match the regex"
      ;;
    "mgc")
      When run mgc object-storage buckets create "$bucket_name"
      The error should include "InvalidBucketName"
      ;;
    "rclone")
      When run rclone mkdir "$profile:$bucket_name" -v
      The error should include "Failed to mkdir"
      ;;
    esac
    The status should be failure
  End
End
