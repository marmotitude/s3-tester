Describe 'Validate API KEY auth' category:"API KEY" id:"074"
  setup(){
    api_key_name="test-074-$(date +%s)"
    bucket_name="test-074-$(date +%s)"
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
    mgc object-storage api-key set --uuid="$api_key_uuid"
    case "$client" in
    "mgc")
      When run mgc object-storage buckets create "$bucket_name-$client"
      The status should be success
      The output should include "Created bucket $bucket_name-$client"
      ;;
    esac
  End
End