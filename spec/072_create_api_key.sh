Describe 'Create API KEY' category:"API KEY"
  setup(){
    api_key_name="test-001-$(date +%s)"
  }
  Before setup
  After teardown
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "with unique name on profile $1 using client $2" id:"072"
    profile=$1
    client=$2
    case "$client" in
    "mgc")
      When run mgc object-storage create --name="$api_key_name"
      The status should be success
      The output should include "Key created successfully"
      ;;
    esac
  End
End
