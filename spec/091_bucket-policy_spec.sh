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
    if [ "$prefix" = true ]; then
      action=[$action]
    else
      action="$action"
    fi
    if [ "$principal" = "*" ]; then
      local principal_entry="\"Principal\": \"*\""
    else
      local principal_entry="\"Principal\": {\"CanonicalUser\": \"$principal\"}"
    fi
    cat <<EOF
{
    "Version": "2012-10-17",
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

Describe 'Put bucket policy:' category:"Bucket Management"
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
    wait_command bucket-exists $profile "$bucket_name-$client"
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
    aws s3 rb s3://$bucket_name-$client --profile $profile --force > /dev/null
    wait_command bucket-not-exists "$profile" "$bucket_name-$client"
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
  Example "on profile $1 using client $2" id:"092"
    profile=$1
    client=$2
    #policy vars
    action='"s3:ListBucket","s3:GetObject"'
    principal="*"
    resource=("$bucket_name-$client" "$bucket_name/*")
    effect="Allow"
    policy=$(setup_policy $bucket_name $client $profile)
    echo $policy
    wait_command bucket-exists $profile "$bucket_name-$client"
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
    aws s3 rb s3://$bucket_name-$client --profile $profile --force > /dev/null
    wait_command bucket-not-exists "$profile" "$bucket_name-$client"
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
    id_principal=$(aws --profile $profile s3api list-buckets | jq -r '.Owner.ID')
    principal="$id_principal"
    resource="$bucket_name-$client/*"
    effect="Allow"
    policy=$(setup_policy $bucket_name $client $profile)
    wait_command bucket-exists $profile "$bucket_name-$client"
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
    #aws s3 rb s3://$bucket_name-$client --profile $profile --force > /dev/null
    #wait_command bucket-not-exists "$profile" "$bucket_name-$client"
  End
End

Describe 'Alternativa para object-lock:' category:"Bucket Management"
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
    wait_command bucket-exists $profile "$bucket_name-$client"
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
    aws s3 rb s3://$bucket_name-$client --profile $profile --force > /dev/null
    wait_command bucket-not-exists "$profile" "$bucket_name-$client"
  End
End

