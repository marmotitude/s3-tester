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
    if [ "$prefix" = true ]; then
      version_num="2012-10-17"
    else
      version_num="2024-07-19"
    fi
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
    "Version": "$version_num",
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

policy-without() {
  local policy=$1
  local removing_field=$(echo $2 | tr -d \":)
  echo $policy | jq "{Version, Statement: .Statement | map(del(.$removing_field))}"
}

policy-with-empty() {
  local policy=$1
  local affected_field=$(echo $2 | tr -d \":)
  echo $policy | jq ".Statement[].$affected_field"
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
      mgc profile set $profile > /dev/null
      When run mgc object-storage buckets policy set --dst $bucket_name-$client --policy "$policy"
      The stdout should include "$bucket_name-$client"
      The status should be success
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
      mgc profile set $profile > /dev/null
      When run mgc object-storage buckets policy delete --dst $bucket_name-$client
      The stdout should include "$bucket_name-$client"
      The status should be success
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
      mgc profile set $profile > /dev/null
      When run mgc object-storage buckets policy set --dst $bucket_name-$client --policy "$policy"
      The stdout should include "$bucket_name-$client"
      The status should be success
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
      mgc profile set $profile > /dev/null
      When run mgc object-storage buckets list --dst $bucket_name-$client
      The stdout should include $file1_name
      The status should be success
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
      mgc profile set $profile-second > /dev/null
      When run mgc object-storage objects download --src $bucket_name-$client/$file1_name --dst $file1_name-3
      The stdout should include $file1_name
      The status should be success
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
      mgc profile set $profile > /dev/null
      When run mgc object-storage buckets policy set --dst $bucket_name-$client --policy "$policy"
      The stdout should include ""
      The status should be success
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
      mgc profile set $profile-second > /dev/null
      When run mgc object-storage objects download --src $bucket_name-$client/$file1_name --dst $file1_name-2
      The stdout should include $file1_name
      The status should be success
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
      mgc profile set $profile > /dev/null
      When run mgc object-storage buckets policy set --dst $bucket_name-$client --policy "$policy"
      The stdout should include ""
      The status should be success
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
      mgc profile set $profile > /dev/null
      When run mgc object-storage objects delete --dst $bucket_name-$client
      The stdout should include ""
      The status should be success
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    aws --profile $profile s3api delete-bucket-policy --bucket "$bucket_name-$client" > /dev/null
    rclone purge $profile:$bucket_name-$client > /dev/null
    #wait_command bucket-not-exists "$profile" "$bucket_name-$client"
  End
End

###
# Malformed policy
###
Describe 'Put bucket policy without Resources:' category:"Bucket Management"
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
    resource="$bucket_name-invalid-$client/*"
    effect="Allow"
    first_policy=$(setup_policy $bucket_name $client $profile)
    policy=$(policy-without "$first_policy" "Resource")
    ensure-bucket-exists $profile $client $bucket_name
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy"
      The status should be failure
      The stderr should include "MalformedPolicy"
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      mgc profile set $profile > /dev/null
      When run mgc object-storage buckets policy set --dst $bucket_name-$client --policy "$policy"
      The status should be failure
      The stdout should include "MalformedPolicy"
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    rclone purge $profile:$bucket_name-$client > /dev/null
  End
End
Describe 'Put bucket policy without Action:' category:"Bucket Management"
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
    resource="$bucket_name-invalid-$client/*"
    effect="Allow"
    first_policy=$(setup_policy $bucket_name $client $profile)
    policy=$(policy-without "$first_policy" "Action")
    ensure-bucket-exists $profile $client $bucket_name
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy"
      The status should be failure
      The stderr should include "MalformedPolicy"
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      mgc profile set $profile > /dev/null
      When run mgc object-storage buckets policy set --dst $bucket_name-$client --policy "$policy"
      The status should be failure
      The stdout should include "MalformedPolicy"
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    rclone purge $profile:$bucket_name-$client > /dev/null
  End
End
Describe 'Put bucket policy without Principal:' category:"Bucket Management"
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
    resource="$bucket_name-invalid-$client/*"
    effect="Allow"
    first_policy=$(setup_policy $bucket_name $client $profile)
    policy=$(policy-without "$first_policy" "Principal")
    ensure-bucket-exists $profile $client $bucket_name
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy"
      The status should be failure
      The stderr should include "MalformedPolicy"
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      mgc profile set $profile > /dev/null
      When run mgc object-storage buckets policy set --dst $bucket_name-$client --policy "$policy"
      The status should be failure
      The stdout should include "MalformedPolicy"
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    rclone purge $profile:$bucket_name-$client > /dev/null
  End
End
Describe 'Put bucket policy without Effect:' category:"Bucket Management"
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
    resource="$bucket_name-invalid-$client/*"
    effect="Allow"
    first_policy=$(setup_policy $bucket_name $client $profile)
    policy=$(policy-without "$first_policy" "Effect")
    ensure-bucket-exists $profile $client $bucket_name
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy"
      The status should be failure
      The stderr should include "MalformedPolicy"
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      mgc profile set $profile > /dev/null
      When run mgc object-storage buckets policy set --dst $bucket_name-$client --policy "$policy"
      The status should be failure
      The stdout should include "MalformedPolicy"
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    rclone purge $profile:$bucket_name-$client > /dev/null
  End
End
Describe 'Put bucket policy with no Statement:' category:"Bucket Management"
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
    resource="$bucket_name-invalid-$client/*"
    effect="Allow"
    policy=$(setup_policy $bucket_name $client $profile | jq 'del(.Statement)')
    ensure-bucket-exists $profile $client $bucket_name
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy"
      The status should be failure
      The stderr should include "MalformedPolicy"
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      mgc profile set $profile > /dev/null
      When run mgc object-storage buckets policy set --dst $bucket_name-$client --policy "$policy"
      The status should be failure
      The stdout should include "MalformedPolicy"
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    rclone purge $profile:$bucket_name-$client > /dev/null
  End
End

###
# Invalid fields
###
Describe 'Put bucket policy with Resource outside bucket:' category:"Bucket Management"
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
    resource="$bucket_name-invalid-$client/*"
    effect="Allow"
    policy=$(setup_policy $bucket_name $client $profile)
    ensure-bucket-exists $profile $client $bucket_name
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy"
      The status should be failure
      The stderr should include "MalformedPolicy"
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      mgc profile set $profile > /dev/null
      When run mgc object-storage buckets policy set --dst $bucket_name-$client --policy "$policy"
      The status should be failure
      The stdout should include "MalformedPolicy"
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    rclone purge $profile:$bucket_name-$client > /dev/null
  End
End
Describe 'Put bucket policy with empty Resource:' category:"Bucket Management"
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
    resource="$bucket_name-invalid-$client/*"
    effect="Allow"
    first_policy=$(setup_policy $bucket_name $client $profile)
    policy=$(policy-with-empty "$first_policy" "Resource")
    ensure-bucket-exists $profile $client $bucket_name
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy"
      The status should be failure
      The stderr should include "MalformedPolicy"
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      mgc profile set $profile > /dev/null
      When run mgc object-storage buckets policy set --dst $bucket_name-$client --policy "$policy"
      The status should be failure
      The stdout should include "MalformedPolicy"
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    rclone purge $profile:$bucket_name-$client > /dev/null
  End
End
Describe 'Put bucket policy with empty Action:' category:"Bucket Management"
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
    resource="$bucket_name-invalid-$client/*"
    effect="Allow"
    first_policy=$(setup_policy $bucket_name $client $profile)
    policy=$(policy-with-empty "$first_policy" "Action")
    ensure-bucket-exists $profile $client $bucket_name
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy"
      The status should be failure
      The stderr should include "MalformedPolicy"
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      mgc profile set $profile > /dev/null
      When run mgc object-storage buckets policy set --dst $bucket_name-$client --policy "$policy"
      The status should be failure
      The stdout should include "MalformedPolicy"
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    rclone purge $profile:$bucket_name-$client > /dev/null
  End
End
Describe 'Put bucket policy with empty Principal:' category:"Bucket Management"
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
    resource="$bucket_name-invalid-$client/*"
    effect="Allow"
    first_policy=$(setup_policy $bucket_name $client $profile)
    policy=$(policy-with-empty "$first_policy" "Principal")
    ensure-bucket-exists $profile $client $bucket_name
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy"
      The status should be failure
      The stderr should include "MalformedPolicy"
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      mgc profile set $profile > /dev/null
      When run mgc object-storage buckets policy set --dst $bucket_name-$client --policy "$policy"
      The status should be failure
      The stdout should include "MalformedPolicy"
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    rclone purge $profile:$bucket_name-$client > /dev/null
  End
End
Describe 'Put bucket policy with empty Effect:' category:"Bucket Management"
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
    resource="$bucket_name-invalid-$client/*"
    effect="Allow"
    first_policy=$(setup_policy $bucket_name $client $profile)
    policy=$(policy-with-empty "$first_policy" "Effect")
    ensure-bucket-exists $profile $client $bucket_name
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy"
      The status should be failure
      The stderr should include "MalformedPolicy"
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      mgc profile set $profile > /dev/null
      When run mgc object-storage buckets policy set --dst $bucket_name-$client --policy "$policy"
      The status should be failure
      The stdout should include "MalformedPolicy"
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    rclone purge $profile:$bucket_name-$client > /dev/null
  End
End
Describe 'Put bucket policy with empty Statement:' category:"Bucket Management"
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
    resource="$bucket_name-invalid-$client/*"
    effect="Allow"
    policy=$(setup_policy $bucket_name $client $profile | jq '.Statement |= []')
    ensure-bucket-exists $profile $client $bucket_name
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      When run aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy"
      The status should be failure
      The stderr should include "MalformedPolicy"
      ;;
    "rclone")
      Skip "Skipped test to $client"
      ;;
    "mgc")
      mgc profile set $profile > /dev/null
      When run mgc object-storage buckets policy set --dst $bucket_name-$client --policy "$policy"
      The status should be failure
      The stdout should include "MalformedPolicy"
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    rclone purge $profile:$bucket_name-$client > /dev/null
  End
End
