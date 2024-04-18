Describe 'Revoke API KEY' category:"API KEY" id:"076"
  setup(){
    api_key_name="test-002-$(date +%s)"
  }
  Before setup
  After teardown
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "with unique name on profile $1 using client $2"
    profile=$1
    client=$2
    api_key_uuid=$(mgc object-storage api-key revoke --name "$api_key_name" --cli.output=json | jq -r '.uuid')
    case "$client" in
    "mgc")
      When run mgc object-storage revoke --uuid="$api_key_uuid"
      The status should be success
      The output should include "Key deleted successfully"
      ;;
    esac
  End
End