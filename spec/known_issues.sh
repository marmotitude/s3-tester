# Function to help skip know issues while the fixes are not deployed

skip_known_issues(){
  issue=$1
  profile=$2
  client=$3
  # Check if SKIP_KNOWN_ISSUES is set to "yes"
  if [[ "${SKIP_KNOWN_ISSUES,,}" == "yes" ]]; then
    if [[ "$issue" == "894" && ( "$client" == "rclone" || "$client" == "mgc" ) ]]; then
      return 0  # Issue should be skipped
    fi
  fi

  return 1  # Issue should not be skipped
}
