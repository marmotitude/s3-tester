# Service account tests
# =====================
#
# Service accounts in the context of the following tests are accounts created with no permissions,
# they cannot list buckets and cannot create new buckets. All read and write access of object by
# those service accounts needs to be explicited as an "Allow" rule in a Bucket Policy Statement.
# =====================

# test if a profile is set on aws cli tool
check_missing_profile() {
  profile_arg=$1
  key_id=$(aws configure get profile.$profile_arg.aws_access_key_id)
  # true if key_id is null
  [ -z "$key_id" ]
}


Describe "Service Accounts: " category:"Service Accounts"  id:"201"
  setup(){
    bucket_name="test-091-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Describe "Should NOT be able to" category:"Service Accounts"  id:"201"
    Example "list buckets."
      profile=$1
      sa_profile=$profile-sa
      client=$2

      Skip if "Profile "$sa_profile" is missing" check_missing_profile "$sa_profile"
      if $(check_missing_profile "$profile"); then return; fi # ! SKIP DOES NOT SKIP

      case "$client" in
      "aws-s3api" | "aws" | "aws-s3")
        When run aws --profile $sa_profile s3api list-buckets
        The stderr should include "AccessDenied"
        The status should be failure
        ;;
      "rclone")
        When run rclone lsd $sa_profile:
        The stderr should include "AccessDenied"
        The status should be failure
        ;;
      "mgc")
        # mgc 0.25.0 uses workspace set to change profiles (not set profile as 0.21)
        mgc workspace set $sa_profile > /dev/null
        When run mgc object-storage buckets list --raw
        The status should be failure
        The stderr should include "AccessDenied"
        ;;
      esac
    End
    Example "create bucket."
      profile=$1
      sa_profile=$profile-sa
      client=$2

      Skip if "Profile "$sa_profile" is missing" check_missing_profile "$sa_profile"
      if $(check_missing_profile "$profile"); then return; fi # ! SKIP DOES NOT SKIP

      case "$client" in
      "aws-s3api" | "aws" | "aws-s3")
        When run aws --profile $sa_profile s3api create-bucket --bucket $bucket_name
        The stderr should include "AccessDenied"
        The status should be failure
        ;;
      "rclone")
        When run rclone mkdir $sa_profile:$bucket_name
        The stderr should include "AccessDenied"
        The status should be failure
        ;;
      "mgc")
        # mgc 0.25.0 uses workspace set to change profiles (not set profile as 0.21)
        mgc workspace set $sa_profile > /dev/null
        When run mgc object-storage buckets create --bucket $bucket_name --raw
        The status should be failure
        The stderr should include "AccessDenied"
        ;;
      esac
    End
  End
End
