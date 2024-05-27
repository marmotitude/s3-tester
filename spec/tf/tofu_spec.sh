Describe "Tofu with hashicorp s3 provider" category:"terraform" id:"101"


  Parameters:matrix
    $PROFILES
  End
  Example "setup"
    profile=$1
    PROJECT_FOLDER="/tmp/tofuproject-$profile"
    # create temporary project folder
    mkdir -p $PROJECT_FOLDER
    # copy plans
    When run cp spec/tf/*.tf $PROJECT_FOLDER/.
    The status should be success
  End
  Example "install providers"
    profile=$1
    cd "/tmp/tofuproject-$profile"
    When run tofu init
    The output should include "nstalled hashicorp/aws"
    The output should include "OpenTofu has been successfully initialized!"
    The status should be success
  End
  Example "apply plans"
    profile=$1
    cd "/tmp/tofuproject-$profile"
    When run tofu apply -var "profile=$profile" -auto-approve
    The output should include "Apply complete! Resources: 3 added, 0 changed, 0 destroyed."
    The status should be success
  End
  Example "destroy all"
    profile=$1
    cd "/tmp/tofuproject-$profile"
    When run tofu destroy -var "profile=$profile" -auto-approve
    The output should include "Destroy complete! Resources: 3 destroyed."
    The status should be success
  End
  Example "teardown"
    profile=$1
    ls "/tmp/tofuproject-$profile"
    # remove tempporary project folder
    When run rm -rf "/tmp/tofuproject-$profile"
    The status should be success
  End
End

