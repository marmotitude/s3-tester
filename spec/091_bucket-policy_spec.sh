# Constants
% PRINCIPAL_LIST: "\"*\" CanonicalUser"

# import functions: wait_command
Include ./spec/019_utils.sh
is_variable_null() {
  [ -z "$1" ]
}

setup_policy(){
    local bucket_name=$1
    local client=$2
    local profile=$3
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client > /dev/null
    local get_access=$(aws s3api --profile $profile get-public-access-block --bucket $bucket_name-$client | jq -r '.PublicAccessBlockConfiguration.BlockPublicAcls')
    if [ $get_access = true ];then
      aws s3api --profile $profile put-bucket-ownership-controls --bucket $bucket_name-$client --ownership-controls="Rules=[{ObjectOwnership=BucketOwnerPreferred}]" > /dev/null
      aws s3api --profile $profile put-public-access-block --bucket $bucket_name-$client --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false > /dev/null
      policy_factory true
    else
      policy_factory false
    fi
    }

policy_factory(){
    local prefix=$1
    resource_list=()
    for res in "${resource[@]}"; do
      if [ "$prefix" = true ]; then
        resource_list+="\"arn:aws:s3:::$res\","
      else
        resource_list+="\"$res\","
      fi
    done
    resource_list=${resource_list%,}
    if [ "$principal" = "*" ]; then
      local principal_entry="\"Principal\": \"*\""
    else
      if [ "$principal" = "CanonicalUser" ]; then
        principal=$(aws s3api --profile $profile list-buckets | jq -r '.Owner.ID')
      fi
      if [ "$prefix" = true ]; then
        local principal_entry="\"Principal\": {\"CanonicalUser\": \"$principal\"}"
      else
        local principal_entry="\"Principal\": [\"$principal\"]"
      fi
    fi
    cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "$effect",
            $principal_entry,
            "Action": [$action],
            "Resource": [$resource_list]
        }
    ]
}
EOF
  }

ensure-bucket-exists() {
  profile=$1
  client=$2
  bucket_name=$3
  wait_command bucket-exists $profile "$bucket_name-$client"
  if [ $? -ne 0 ]; then
    create_bucket $profile $client $bucket_name
  fi
}

Describe 'Put bucket policy:' category:"Bucket Management"
  setup(){
    bucket_name="test-091-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
    $PRINCIPAL_LIST
  End
  Example "on profile $1 using client $2 for principal $(echo $3 | tr -d \"):" id:"091"
    profile=$1
    client=$2
    principal=$(echo $3 | tr -d \")
    #policy vars
    action='"s3:GetObject"'
    resource="$bucket_name-$client/*"
    effect="Allow"
    policy=$(setup_policy $bucket_name $client $profile)
    ensure-bucket-exists $profile $client $bucket_name
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy"
      The stdout should include ""
      The status should be success
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      Skip "Skipped test to $client"
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    rclone purge $profile:$bucket_name-$client > /dev/null
    #wait_command bucket-not-exists "$profile" "$bucket_name-$client"
  End
End

Describe 'Delete bucket policy:' category:"Bucket Management"
  setup(){
    bucket_name="test-091-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"091"
    profile=$1
    client=$2
    #policy vars
    action='"s3:GetObject"'
    principal="*"
    resource="$bucket_name-$client/*"
    effect="Allow"
    policy=$(setup_policy $bucket_name $client $profile)
    ensure-bucket-exists $profile $client $bucket_name
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile s3api delete-bucket-policy --bucket "$bucket_name-$client"
      The stdout should include ""
      The status should be success
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      Skip "Skipped test to $client"
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    rclone purge $profile:$bucket_name-$client > /dev/null
    #wait_command bucket-not-exists "$profile" "$bucket_name-$client"
  End
End

Describe 'Easy public bucket policy:' category:"Bucket Management"
  setup(){
    bucket_name="test-091-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"091"
    profile=$1
    client=$2
    #policy vars
    action='"s3:ListBucket","s3:GetObject"'
    principal="*"
    resource=("$bucket_name-$client" "$bucket_name-$client/*")
    effect="Allow"
    policy=$(setup_policy $bucket_name $client $profile)
    ensure-bucket-exists $profile $client $bucket_name
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy"
      The stdout should include ""
      The status should be success
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      Skip "Skipped test to $client"
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    rclone purge $profile:$bucket_name-$client > /dev/null
    #wait_command bucket-not-exists "$profile" "$bucket_name-$client"
  End
End

Describe 'Validate List Easy public bucket policy:' category:"Bucket Management"
  setup(){
    bucket_name="test-091-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"091"
    profile=$1
    client=$2
    id=$(aws s3api --profile $profile-second list-buckets | jq -r '.Owner.ID')
    Skip if "No such a "$profile-second" user" is_variable_null "$id"
    if $(is_variable_null "$id_principal"); then return; fi # ! SKIP DOES NOT SKIP
    #policy vars
    action='"s3:ListBucket","s3:GetObject"'
    principal="*"
    resource=("$bucket_name-$client" "$bucket_name-$client/*")
    effect="Allow"
    policy=$(setup_policy $bucket_name $client $profile)
    ensure-bucket-exists $profile $client $bucket_name
    aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy" > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile-second s3api list-objects-v2 --bucket $bucket_name-$client
      The stdout should include $file1_name
      The status should be success
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      Skip "Skipped test to $client"
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    rclone purge $profile:$bucket_name-$client > /dev/null
    #wait_command bucket-not-exists "$profile" "$bucket_name-$client"
  End
End

Describe 'Validate Get Easy public bucket policy:' category:"Bucket Management"
  setup(){
    bucket_name="test-091-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"091"
    profile=$1
    client=$2
    #policy vars
    id=$(aws s3api --profile $profile-second list-buckets | jq -r '.Owner.ID')
    Skip if "No such a "$profile-second" user" is_variable_null "$id"
    if $(is_variable_null "$id_principal"); then return; fi # ! SKIP DOES NOT SKIP
    action='"s3:ListBucket","s3:GetObject"'
    principal="*"
    resource=("$bucket_name-$client" "$bucket_name-$client/*")
    effect="Allow"
    policy=$(setup_policy $bucket_name $client $profile)
    ensure-bucket-exists $profile $client $bucket_name
    aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy" > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile-second s3 cp s3://$bucket_name-$client/$file1_name $file1_name-3
      The stdout should include $file1_name
      The status should be success
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      Skip "Skipped test to $client"
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    rclone purge $profile:$bucket_name-$client > /dev/null
    #wait_command bucket-not-exists "$profile" "$bucket_name-$client"
  End
End

Describe 'Buckets exclusive to a specific team:' category:"Bucket Management"
  setup(){
    bucket_name="test-091-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"091"
    profile=$1
    client=$2
    #policy vars
    action='"s3:GetObject"'
    id_principal=$(aws --profile $profile-second s3api list-buckets | jq -r '.Owner.ID')
    Skip if "No such a "$profile-second" user" is_variable_null "$id_principal"
    if $(is_variable_null "$id_principal"); then return; fi # ! SKIP DOES NOT SKIP
    principal="$id_principal"
    resource="$bucket_name-$client/*"
    effect="Allow"
    policy=$(setup_policy $bucket_name $client $profile)
    ensure-bucket-exists $profile $client $bucket_name
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy"
      The stdout should include ""
      The status should be success
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      Skip "Skipped test to $client"
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    rclone purge $profile:$bucket_name-$client > /dev/null
    #wait_command bucket-not-exists "$profile" "$bucket_name-$client"
  End
End

Describe 'Validate Buckets exclusive to a specific team:' category:"Bucket Management"
  setup(){
    bucket_name="test-091-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"091"
    profile=$1
    client=$2
    #policy vars
    action='"s3:GetObject"'
    id_principal=$(aws --profile $profile-second s3api list-buckets | jq -r '.Owner.ID')
    Skip if "No such a "$profile-second" user" is_variable_null "$id_principal"
    if $(is_variable_null "$id_principal"); then return; fi # ! SKIP DOES NOT SKIP
    principal="$id_principal"
    resource="$bucket_name-$client/*"
    effect="Allow"
    policy=$(setup_policy $bucket_name $client $profile)
    echo $policy
    ensure-bucket-exists $profile $client $bucket_name
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy" > /dev/null
      When run aws --profile $profile-second s3 cp s3://$bucket_name-$client/$file1_name $file1_name-2
      The stdout should include $file1_name
      The status should be success
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      Skip "Skipped test to $client"
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    rclone purge $profile:$bucket_name-$client > /dev/null
    #wait_command bucket-not-exists "$profile" "$bucket_name-$client"
  End
End

Describe 'Alternative to object-lock:' category:"Bucket Management"
  setup(){
    bucket_name="test-091-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"091"
    profile=$1
    client=$2
    #policy vars
    action='"s3:DeleteObject"'
    principal="*"
    resource="$bucket_name-$client/$file1_name"
    effect="Deny"
    policy=$(setup_policy $bucket_name $client $profile)
    ensure-bucket-exists $profile $client $bucket_name
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy"
      The stdout should include ""
      The status should be success
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      Skip "Skipped test to $client"
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    aws --profile $profile s3api delete-bucket-policy --bucket "$bucket_name-$client" > /dev/null
    rclone purge $profile:$bucket_name-$client > /dev/null
    #wait_command bucket-not-exists "$profile" "$bucket_name-$client"
  End
End

Describe 'Validate Alternative to object-lock:' category:"Bucket Management"
  setup(){
    bucket_name="test-091-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2" id:"091"
    profile=$1
    client=$2
    #policy vars
    action='"s3:DeleteObject"'
    principal="*"
    resource="$bucket_name-$client/$file1_name"
    effect="Deny"
    policy=$(setup_policy $bucket_name $client $profile)
    ensure-bucket-exists $profile $client $bucket_name
    aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy" > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile s3 rm s3://$bucket_name-$client/$file1_name
      The stderr should include "AccessDenied"
      The status should be failure
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      Skip "Skipped test to $client"
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    aws --profile $profile s3api delete-bucket-policy --bucket "$bucket_name-$client" > /dev/null
    rclone purge $profile:$bucket_name-$client > /dev/null
    #wait_command bucket-not-exists "$profile" "$bucket_name-$client"
  End
End
