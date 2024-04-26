Describe 'Validate api key in delegate account' category:"API KEY" id:"075"
  setup() {
    api_key_name="test-075-$(date +%s)"
  }
  Before setup
    Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "with unique name on profile $1 using client $2"
    profile=$1
    client=$2

    case "$client" in
    "mgc")
      mgc profile set-current "$profile"
      delegate_uuid=$(mgc auth tenant list | jq -r 'first(.[] | select(.is_delegated==true)) | .uuid')
      mgc auth tenant set --uuid= "$delegate_uuid"
      run mgc object-storage api-key create --name="$api_key_name"
      When run mgc object-storage buckets list --cli.output=json
      The status should be success
      The output should include "Buckets"
      The output should include "Owner"
      The output should include "DisplayName"
      The output should include "ID"
      The output should include "CreationDate"
      The output should include "Name"
      api_key_uuid=$(mgc object-storage api-key list --cli.output=json | jq -r 'first(.[] | select(.name=="'"$api_key_name"'")) | .uuid')
      mgc object-storage api-key revoke --uuid="$api_key_uuid" -f
      ;;
    esac
  End
End
