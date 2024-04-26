#!/bin/bash
Describe 'Create API KEY' category:"API KEY" id:"072"
  setup() {
    api_key_name="test-creation-$(date +%F)"
  }
  Before setup
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "create api key with unique name on profile $1 using client $2"
    client=$2
    profile=$1
    case "$client" in
    "mgc")
      mgc profile set-current "$profile" >/dev/null
      When run mgc object-storage api-key create --name="$api_key_name"
      The status should be success
      The output should include "Key created successfully"
      api_key_uuid=$(mgc object-storage api-key list --cli.output=json | jq -r 'first(.[] | select(.name=="'"$api_key_name"'")) | .uuid')
      mgc object-storage api-key revoke --uuid="$api_key_uuid" -f
      ;;
    esac
  End
End
