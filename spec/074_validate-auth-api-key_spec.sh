Describe 'Validate API KEY auth' category:"API KEY" id:"074"
  setup() {
    api_key_name="test-074-$(date +%s)"
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
      mgc profile set-current "$profile" >/dev/null
      api_key_uuid=$(mgc object-storage api-key create "$api_key_name" --cli.output=json | jq .uuid)
      mgc object-storage api-key set "$api_key_uuid"

      When run mgc object-storage buckets list --cli.output=json
      The status should be success
      The output should include "Buckets"
      The output should include "Owner"
      The output should include "DisplayName"
      The output should include "ID"
      The output should include "CreationDate"
      The output should include "Name"
      mgc object-storage api-key revoke --uuid="$api_key_uuid" -f
      ;;
    esac
  End
End
