Include ./spec/known_issues.sh

delete_bucket() {
  profile=$1
  client=$2
  bucket_name="$3"

  aws --profile "$profile" s3api delete-bucket --bucket "$bucket_name" > /dev/null
  aws --profile "$profile" s3api wait bucket-not-exists --bucket "$bucket_name"
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

  bucket_name="testeee$(openssl rand -hex 40 | tr -dc '[:lower:]' | head -c 40)"
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
        mgc profile set-current $profile > /dev/null
        When run mgc object-storage buckets create "$bucket_name"
        The output should include "Created bucket $bucket_name"
        ;;
      "rclone")
        When run rclone mkdir "$profile:$bucket_name" -v
        The error should include "Bucket \"$bucket_name\" created"
        ;;
      esac
      The status should be success
      aws --profile "$profile" s3api wait bucket-exists --bucket "$bucket_name"
      Assert delete_bucket "$1" "$2" "$bucket_name"
    End
  End

  bucket_name="212121$(openssl rand -hex 40 | tr -dc '0-9' | head -c 40)"
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
        mgc profile set-current $profile > /dev/null
        When run mgc object-storage buckets create "$bucket_name"
        The output should include "Created bucket $bucket_name"
        ;;
      "rclone")
        When run rclone mkdir "$profile:$bucket_name" -v
        The error should include "Bucket \"$bucket_name\" created"
        ;;
      esac
      The status should be success
      aws --profile "$profile" s3api wait bucket-exists --bucket "$bucket_name"
      Assert delete_bucket "$1" "$2" "$bucket_name"
      aws --profile "$profile" s3api wait bucket-not-exists --bucket "$bucket_name"
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
        mgc profile set-current $profile > /dev/null
        When run mgc object-storage buckets create "$bucket_name"
        The output should include "Created bucket $bucket_name"
        ;;
      "rclone")
        When run rclone mkdir "$profile:$bucket_name" -v
        The error should include "Bucket \"$bucket_name\" created"
        ;;
      esac
      The status should be success
      aws --profile "$profile" s3api wait bucket-exists --bucket "$bucket_name"
      Assert delete_bucket "$1" "$2" "$bucket_name"
    End
  End
End
