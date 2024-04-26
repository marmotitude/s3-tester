Describe 'Create api key in delegate account' category:"API KEY" id:"073"
  setup() {
    api_key_name="test-073-$(date +%s)"
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
      When run mgc object-storage api-key create --name="$api_key_name"
      The status should be success
      The output should include "Key created successfully"
      api_key_uuid=$(mgc object-storage api-key list --cli.output=json | jq -r 'first(.[] | select(.name=="'"$api_key_name"'")) | .uuid')
      mgc object-storage api-key revoke --uuid="$api_key_uuid" -f
      ;;
    esac
  End
End
