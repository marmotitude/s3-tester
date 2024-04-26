Describe 'Revoke API KEY' category:"API KEY" id:"076"
  setup() {
    API_KEY_NAME="test-creation-$(date +%F)"
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
      mgc object-storage api-key create --name="$API_KEY_NAME"
      api_key_uuid="$(mgc object-storage api-key list --cli.output=json | jq -r 'first(.[] | select(.name=="'"$API_KEY_NAME"'")) | .uuid')"
      mgc profile set-current "$profile" >/dev/null
      echo "$api_key_uuid"
      When run mgc object-storage api-key revoke --uuid="$api_key_uuid" -f
      The status should be success
      The output should include "revoked!"
      ;;
    esac
  End
End