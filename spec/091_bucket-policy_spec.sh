# Constants
% PRINCIPAL_LIST: "\"*\" CanonicalUser"

# import functions: wait_command
Include ./spec/019_utils.sh
is_variable_null() {
  [ -z "$1" ]
}

has_s3_block_public_access() {
    aws s3api --profile $profile get-public-access-block --bucket $bucket_name-$client | jq -r '.PublicAccessBlockConfiguration.BlockPublicAcls'
}

setup_policy(){
    local bucket_name=$1
    local client=$2
    local profile=$3
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client > /dev/null
    local get_access=$(has_s3_block_public_access)
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
    version_num="2012-10-17"
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
        local principal_entry="\"Principal\": {\"MGC\": \"${principal%%:*}\"}"
      fi
    fi
    if [ ! "$action" = '"s3:*"' ]; then #action can't be ["s3:*"], has to be "s3:*" outside the list
      action="[$action]"
    fi
    cat <<EOF
{
    "Version": "$version_num",
    "Statement": [
        {
            "Effect": "$effect",
            $principal_entry,
            "Action": $action,
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
      Skip "No such operation in client $client"
      ;;
    "mgc")
      mgc workspace set $profile > /dev/null
      When run mgc os buckets policy set --dst $bucket_name-$client --policy "$policy"
      The stdout should include ""
      The status should be success
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    aws --profile $profile s3api delete-bucket-policy --bucket $bucket_name-$client
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
      Skip "No such operation in client $client"
      ;;
    "mgc")
      mgc workspace set $profile > /dev/null
      When run mgc os buckets policy delete --dst $bucket_name-$client
      The stdout should include ""
      The status should be success
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    aws --profile $profile s3api delete-bucket-policy --bucket $bucket_name-$client
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
      Skip "No such operation in client $client"
      ;;
    "mgc")
      mgc workspace set $profile > /dev/null
      When run mgc os buckets policy set --dst $bucket_name-$client --policy "$policy"
      The stdout should include ""
      The status should be success
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    aws --profile $profile s3api delete-bucket-policy --bucket $bucket_name-$client
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
    id=$(aws s3api --profile $profile list-buckets | jq -r '.Owner.ID')
    # if $(is_variable_null "$id_principal"); then return; fi # ! SKIP DOES NOT SKIP
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
      When run rclone ls $profile-second:$bucket_name-$client
      The stdout should include $file1_name
      The status should be success
      ;;
    "mgc")
      mgc workspace set $profile-second > /dev/null
      When run mgc os objects list $bucket_name-$client
      The stdout should include $file1_name
      The status should be success
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    aws --profile $profile s3api delete-bucket-policy --bucket "$bucket_name-$client" > /dev/null
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
    id=$(aws s3api --profile $profile list-buckets | jq -r '.Owner.ID')
    # if $(is_variable_null "$id_principal"); then return; fi # ! SKIP DOES NOT SKIP
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
      When run rclone copy $profile-second:$bucket_name-$client/$file1_name $file1_name-3
      The stdout should include ""
      The status should be success
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
    Skip if "No such a "$profile" user" is_variable_null "$id_principal"
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
      Skip "No such operation in client $client"
      ;;
    "mgc")
      mgc workspace set $profile > /dev/null
      When run mgc os buckets policy set --dst $bucket_name-$client --policy "$policy"
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
    Skip if "No such a "$profile" user" is_variable_null "$id_principal"
    if $(is_variable_null "$id_principal"); then return; fi # ! SKIP DOES NOT SKIP
    principal="$id_principal"
    resource="$bucket_name-$client/*"
    effect="Allow"
    policy=$(setup_policy $bucket_name $client $profile)
    ensure-bucket-exists $profile $client $bucket_name
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
      aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy" > /dev/null
      When run aws --profile $profile-second s3 cp s3://$bucket_name-$client/$file1_name $file1_name-2
      The stdout should include $file1_name
      The status should be success
      ;;
    "rclone")
      Skip "No such operation in client $client"
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
      Skip "No such operation in client $client"
      ;;
    "mgc")
      mgc workspace set $profile > /dev/null
      When run mgc os buckets policy set --dst $bucket_name-$client --policy "$policy"
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
      When run aws --profile $profile-second s3 rm s3://$bucket_name-$client/$file1_name
      The stderr should include "AccessDenied"
      The status should be failure
      ;;
    "rclone")
      When run rclone delete $profile-second:$bucket_name-$client/$file1_name
      The stderr should include "AccessDenied"
      The status should be failure
      ;;
    "mgc")
      mgc workspace set $profile-second
      When run mgc os objects delete $bucket_name-$client/$file1_name --no-confirm
      The stderr should include "Error: (AccessDeniedByBucketPolicy) 403 Forbidden - Access Denied. Bucket Policy violated."
      The status should be failure
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
      Skip "No such operation in client $client"
      ;;
    "mgc")
      mgc workspace set $profile > /dev/null
      When run mgc os buckets policy set --dst $bucket_name-$client --policy "$policy"
      The status should be failure
      The stderr should include "MalformedPolicy"
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
      Skip "No such operation in client $client"
      ;;
    "mgc")
      mgc workspace set $profile > /dev/null
      When run mgc os buckets policy set --dst $bucket_name-$client --policy "$policy"
      The status should be failure
      The stderr should include "MalformedPolicy"
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
      Skip "No such operation in client $client"
      ;;
    "mgc")
      mgc workspace set $profile > /dev/null
      When run mgc os buckets policy set --dst $bucket_name-$client --policy "$policy"
      The status should be failure
      The stderr should include "MalformedPolicy"
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
      Skip "No such operation in client $client"
      ;;
    "mgc")
      mgc workspace set $profile > /dev/null
      When run mgc os buckets policy set --dst $bucket_name-$client --policy "$policy"
      The status should be failure
      The stderr should include "MalformedPolicy"
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
      Skip "No such operation in client $client"
      ;;
    "mgc")
      mgc workspace set $profile > /dev/null
      When run mgc os buckets policy set --dst $bucket_name-$client --policy "$policy"
      The status should be failure
      The stderr should include "MalformedPolicy"
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
      Skip "No such operation in client $client"
      ;;
    "mgc")
      mgc workspace set $profile > /dev/null
      When run mgc os buckets policy set --dst $bucket_name-$client --policy "$policy"
      The status should be failure
      The stderr should include "MalformedPolicy"
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
      Skip "No such operation in client $client"
      ;;
    "mgc")
      mgc workspace set $profile > /dev/null
      When run mgc os buckets policy set --dst $bucket_name-$client --policy "$policy"
      The status should be failure
      The stderr should include "flag \"--policy=null\" error: invalid \"/0\": json: cannot unmarshal array into Go value of type map[string]interface {}"
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
      Skip "No such operation in client $client"
      ;;
    "mgc")
      mgc workspace set $profile > /dev/null
      When run mgc os buckets policy set --dst $bucket_name-$client --policy "$policy"
      The status should be failure
      The stderr should include "flag \"--policy=null\" error: invalid \"/0\": json: cannot unmarshal array into Go value of type map[string]interface {}"
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
      Skip "No such operation in client $client"
      ;;
    "mgc")
      mgc workspace set $profile > /dev/null
      When run mgc os buckets policy set --dst $bucket_name-$client --policy "$policy"
      The status should be failure
      The stderr should include "flag \"--policy=null\" error: invalid \"/0\": json: cannot unmarshal string into Go value of type map[string]interface {}"
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
      Skip "No such operation in client $client"
      ;;
    "mgc")
      mgc workspace set $profile > /dev/null
      When run mgc os buckets policy set --dst $bucket_name-$client --policy "$policy"
      The status should be failure
      The stderr should include "flag \"--policy=null\" error: invalid \"/0\": json: cannot unmarshal string into Go value of type map[string]interface {}"
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
      Skip "No such operation in client $client"
      ;;
    "mgc")
      echo mgc workspace set $profile > /dev/null
      When run mgc os buckets policy set --dst $bucket_name-$client --policy "$policy"
      The status should be failure
      The stderr should include "MalformedPolicy"
      ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    rclone purge $profile:$bucket_name-$client > /dev/null
  End
End

###
# Cross access
###
Describe 'Access other buckets - User 1 gives access to user 3 and user 2 is locked:' category:"Bucket Management"
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

    # Check if other profiles exist, we need 3 for this test to work
    user2id=$(aws s3api --profile $profile-second list-buckets | jq -r '.Owner.ID')
    if $(is_variable_null "$user2id"); then return; fi # ! SKIP DOES NOT SKIP
    user3id=$(aws s3api --profile $profile-third list-buckets | jq -r '.Owner.ID')
    if $(is_variable_null "$user3id"); then return; fi # ! SKIP DOES NOT SKIP

    #policy vars
    action='"s3:ListBucket","s3:GetObject"'
    principal="$user3id"
    resource=("$bucket_name-$client" "$bucket_name-$client/*")
    effect="Allow"
    policy=$(setup_policy $bucket_name $client $profile)
    ensure-bucket-exists $profile $client $bucket_name
    aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy" > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
        When run aws --profile $profile-second s3api list-objects-v2 --bucket "$bucket_name-$client"
        The stderr should include "An error occurred (AccessDeniedByBucketPolicy) when calling the ListObjectsV2 operation: Access Denied."
        The status should be failure
        ;;
    "rclone")
        When run rclone ls $profile-second:$bucket_name-$client
        The stderr should include "AccessDeniedByBucketPolicy: Access Denied. Bucket Policy violated."
        The status should be failure
        ;;
    "mgc")
        mgc workspace set $profile-second
        When run mgc os objects list --dst "$bucket_name-$client"
        The stderr should include "(AccessDeniedByBucketPolicy) 403 Forbidden - Access Denied. Bucket Policy violated."
        The stdout should include ""
        The status should be failure
        ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    aws --profile $profile s3api delete-bucket-policy --bucket "$bucket_name-$client" > /dev/null
    rclone purge $profile:$bucket_name-$client > /dev/null
  End
End

Describe 'Access other buckets - User 1 gives read access to user 2 and user 2 cannot do other operations:' category:"Bucket Management"
  local ready=false
  setup(){
    bucket_name="test-091-$(date +%s)"
    file1_name="LICENSE"
  }
  BeforeAll 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2: setup policy" id:"091"
    profile=$1
    client=$2

    # Check if other profiles exist
    user2id=$(aws s3api --profile $profile-second list-buckets | jq -r '.Owner.ID')
    if $(is_variable_null "$user2id"); then
      return # ! SKIP DOES NOT SKIP
    else
      ready=true
    fi

    #policy vars
    action='"s3:ListBucket","s3:GetObject"'
    principal="$user2id"
    resource=("$bucket_name-$client" "$bucket_name-$client/*")
    effect="Allow"
    policy=$(setup_policy $bucket_name $client $profile)

    ensure-bucket-exists $profile $client $bucket_name
    When run aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy" > /dev/null
    The status should be success
    echo "Created policy in bucket $bucket_name" > /dev/null
  End
  Example "on profile $1 using client $2: user tries to read" id:"091"
    profile=$1
    client=$2
    [ ! $ready ] && Skip "Test was not correctly setup" && return
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
        When run aws --profile $profile-second s3api list-objects-v2 --bucket $bucket_name-$client
        The stdout should include $file1_name
        The status should be success
        ;;
    "rclone")
        When run rclone ls $profile-second:$bucket_name-$client
        The stdout should include $file1_name
        The status should be success
        ;;
    "mgc")
        mgc workspace set $profile-second
        When run mgc os objects list --dst $bucket_name-$client
        The stdout should include $file1_name
        The status should be success
        ;;
    esac
  End
  Example "on profile $1 using client $2: user tries to write" id:"091"
    profile=$1
    client=$2
    [ ! $ready ] && Skip "Test was not correctly setup" && return
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
        When run aws --profile $profile-second s3api put-object --bucket $bucket_name-$client --key $file1_name-copy --body "$(pwd)/$file1_name"
        The stderr should include "An error occurred (AccessDeniedByBucketPolicy) when calling the PutObject operation: Access Denied. Bucket Policy violated."
        The status should be failure
        ;;
    "rclone")
        When run rclone copy "$(pwd)/$file1_name" $profile-second:$bucket_name-$client/$file1_name-copy
        The stderr should include "AccessDeniedByBucketPolicy: Access Denied. Bucket Policy violated."
        The status should be failure
        ;;
    "mgc")
        mgc workspace set $profile-second
        When run mgc os objects upload --dst $bucket_name-$client/$file1_name-copy --src $file1_name
        The stderr should include "Error: (AccessDeniedByBucketPolicy) 403 Forbidden - Access Denied. Bucket Policy violated."
        The stdout should include ""
        The status should be failure
        ;;
    esac
  End
  Example "on profile $1 using client $2: user tries to delete" id:"091"
    profile=$1
    client=$2
    [ ! $ready ] && Skip "Test was not correctly setup" && return
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
        When run aws --profile $profile-second s3api delete-object --bucket $bucket_name-$client --key $file1_name
        The stderr should include "An error occurred (AccessDeniedByBucketPolicy) when calling the DeleteObject operation: Access Denied. Bucket Policy violated."
        The status should be failure
        ;;
    "rclone")
        When run rclone delete $profile-second:$bucket_name-$client/$file1_name
        The stderr should include "AccessDeniedByBucketPolicy: Access Denied. Bucket Policy violated."
        The status should be failure
        ;;
    "mgc")
        mgc workspace set $profile-second
        When run mgc os objects delete $bucket_name-$client/$file1_name --no-confirm
        The stderr should include "Error: (AccessDeniedByBucketPolicy) 403 Forbidden - Access Denied. Bucket Policy violated."
        The status should be failure
        ;;
    esac
  End
  Example "on profile $1 using client $2: user tries to remove policy" id:"091"
    profile=$1
    client=$2
    [ ! $ready ] && Skip "Test was not correctly setup" && return
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
        When run aws --profile $profile-second s3api delete-bucket-policy --bucket $bucket_name-$client > /dev/null
        The stderr should include "An error occurred (AccessDenied) when calling the DeleteBucketPolicy operation: Access Denied."
        The status should be failure
        ;;
    "rclone")
        Skip "No such operation in client $client"
        ;;
    "mgc")
        mgc workspace set $profile-second
        When run mgc os buckets policy delete --dst $bucket_name-$client
        The stderr should include "Error: (AccessDenied) 403 Forbidden - Access Denied."
        The stdout should include ""
        The status should be failure
        ;;
    esac
  End
  Example "on profile $1 using client $2: cleanup" id:"091"
    profile=$1
    client=$2
    [ ! $ready ] && Skip "Test was not correctly setup" && return
    cleanup() {
    wait_command bucket-exists $profile "$bucket_name-$client" \
      && aws --profile $profile s3api delete-bucket-policy --bucket "$bucket_name-$client" > /dev/null \
      && rclone purge $profile:$bucket_name-$client > /dev/null \
      || true
    }
    When run cleanup
    The status should be success
    The stdout should include "last wait bucket-exists for profile profile"
  End
End

Describe 'Access other buckets - User 1 gives write access to user 2 and user 2 cannot do other operations:' category:"Bucket Management"
  setup(){
    bucket_name="test-091-$(date +%s)"
    file1_name="LICENSE"
  }
  BeforeAll 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "on profile $1 using client $2: setup policy" id:"091"
    profile=$1
    client=$2

    # Check if other profiles exist
    user2id=$(aws s3api --profile $profile-second list-buckets | jq -r '.Owner.ID')
    if $(is_variable_null "$user2id"); then
      return # ! SKIP DOES NOT SKIP
    else
      ready=true
    fi

    #policy vars
    action='"s3:PutObject","s3:GetObject"'
    principal="$user2id"
    resource=("$bucket_name-$client" "$bucket_name-$client/*")
    effect="Allow"
    policy=$(setup_policy $bucket_name $client $profile)
    ensure-bucket-exists $profile $client $bucket_name
    When run aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy" > /dev/null
    The status should be success
    echo "Created policy in bucket $bucket_name" > /dev/null
  End

  Example "on profile $1 using client $2: user tries to read" id:"091"
    profile=$1
    client=$2
    # [ ! $ready ] && Skip "Test was not correctly setup" && return
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
        When run aws --profile $profile-second s3api list-objects-v2 --bucket $bucket_name-$client
        The stderr should include "An error occurred (AccessDeniedByBucketPolicy) when calling the ListObjectsV2 operation: Access Denied. Bucket Policy violated."
        The status should be failure
        ;;
    "rclone")
        When run rclone ls $profile-second:$bucket_name-$client
        The stderr should include "AccessDeniedByBucketPolicy: Access Denied. Bucket Policy violated."
        The status should be failure
        ;;
    "mgc")
        mgc workspace set $profile-second
        When run mgc os objects list $bucket_name-$client
        The stderr should include "403"
        The stdout should include ""
        The status should be failure
        ;;
    esac
  End
  Example "on profile $1 using client $2: user tries to write" id:"091"
    profile=$1
    client=$2
    # [ ! $ready ] && Skip "Test was not correctly setup" && return
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
        When run aws --profile $profile-second s3api put-object --bucket $bucket_name-$client --key $file1_name-copy --body "$(pwd)/$file1_name"
        The stdout should include ""
        The status should be success
        ;;
    "rclone")
        # When run rclone copy "$(pwd)/$file1_name" $profile-second://$bucket_name-$client/$file_name-copy
        # The stdout should include ""
        # The status should be success
        Skip "Skipped test to $client"
        ;;
    "mgc")
        mgc workspace set $profile-second
        When run mgc os objects upload --dst $bucket_name-$client/$file1_name-copy --src $file1_name
        The stdout should include $file1_name
        The status should be success
        ;;
    esac
  End
  Example "on profile $1 using client $2: user tries to delete" id:"091"
    profile=$1
    client=$2
    # [ ! $ready ] && Skip "Test was not correctly setup" && return
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
        When run aws --profile $profile-second s3api delete-object --bucket $bucket_name-$client --key $file1_name 
        The stderr should include "An error occurred (AccessDeniedByBucketPolicy) when calling the DeleteObject operation: Access Denied. Bucket Policy violated."
        The status should be failure
        ;;
    "rclone")
        When run rclone delete $profile-second:$bucket_name-$client/$file1_name
        The stderr should include "AccessDeniedByBucketPolicy: Access Denied. Bucket Policy violated."
        The status should be failure
        ;;
    "mgc")
        mgc workspace set $profile-second
        When run mgc os objects delete $bucket_name-$client/$file1_name --no-confirm
        The stderr should include "Error: (AccessDeniedByBucketPolicy) 403 Forbidden - Access Denied. Bucket Policy violated."
        The status should be failure
        ;;
    esac
  End
  Example "on profile $1 using client $2: user tries to remove policy" id:"091"
    profile=$1
    client=$2
    # [ ! $ready ] && Skip "Test was not correctly setup" && return
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
        When run aws --profile $profile-second s3api delete-bucket-policy --bucket $bucket_name-$client > /dev/null
        The stderr should include "An error occurred (AccessDenied) when calling the DeleteBucketPolicy operation: Access Denied."
        The status should be failure
        ;;
    "rclone")
        Skip "No such operation in client $client"
        ;;
    "mgc")
        mgc workspace set $profile-second
        When run mgc os buckets policy delete --dst $bucket_name-$client
        The stderr should include "Error: (AccessDenied) 403 Forbidden - Access Denied."
        The stdout should include ""
        The status should be failure
        ;;
    esac
  End
  Example "on profile $1 using client $2: cleanup" id:"091"
    profile=$1
    client=$2
    # [ ! $ready ] && Skip "Test was not correctly setup" && return
    cleanup() {
    wait_command bucket-exists $profile "$bucket_name-$client" \
      && aws --profile $profile s3api delete-bucket-policy --bucket "$bucket_name-$client" > /dev/null \
      && rclone purge $profile:$bucket_name-$client > /dev/null \
      || true
    }
    When run cleanup
    The status should be success
    The stdout should include ""
  End
End

Describe 'Owner denies all access but can still change policy:' category:"Bucket Management"
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

    # Check if other profiles exist, we need 3 for this test to work
    user2id=$(aws s3api --profile $profile-second list-buckets | jq -r '.Owner.ID')
    if $(is_variable_null "$user2id"); then return; fi # ! SKIP DOES NOT SKIP
    user3id=$(aws s3api --profile $profile-third list-buckets | jq -r '.Owner.ID')
    if $(is_variable_null "$user3id"); then return; fi # ! SKIP DOES NOT SKIP

    #policy vars
    # action='"s3:DeleteBucketPolicy", "s3:GetBucketAcl", "s3:GetBucketPolicy", "s3:GetBucketPolicyStatus", 
    # "s3:GetBucketVersioning", "s3:ListBucket", "s3:ListBucketMultipartUploads", "s3:ListBucketVersions", 
    # "s3:PutBucketAcl", "s3:PutBucketPolicy", "s3:PutBucketVersioning", "s3:AbortMultipartUpload", "s3:DeleteObject", 
    # "s3:GetObject", "s3:GetObjectAcl", "s3:ListMultipartUploadParts", "s3:PutObject", "s3:PutObjectAcl"'
    action='"s3:*"'
    principal="*"
    resource=("$bucket_name-$client" "$bucket_name-$client/*")
    effect="Deny"
    policy=$(setup_policy $bucket_name $client $profile)
    ensure-bucket-exists $profile $client $bucket_name
    aws --profile $profile s3api put-bucket-policy --bucket $bucket_name-$client --policy "$policy" > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
        When run aws --profile $profile s3api delete-bucket-policy --bucket "$bucket_name-$client"
        The status should be success
        The stdout should include ""
        ;;
    "rclone")
        Skip "No such operation in client $client"
        ;;
    "mgc")
        mgc workspace set $profile
        When run mgc os buckets policy delete --dst "$bucket_name-$client"
        The status should be success
        The stdout should include ""
        ;;
    esac
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    aws --profile $profile s3api delete-bucket-policy --bucket "$bucket_name-$client" > /dev/null
    rclone purge $profile:$bucket_name-$client > /dev/null
  End
End
