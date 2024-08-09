wait_command() {
  command=$1
  profile_to_wait=$2
  bucket_name_to_wait=$3
  object_name_to_wait=$4
  key_argument=$([ -z "$4" ] && echo "" || echo "--key $4")
  number_of_waits=0

  # aws s3api wait does not allow a custom timeout, so we repeat several waits if we need more than
  # the default of 20 attempts, or 100 seconds
  for ((i=1; i<=number_of_waits; i++))
  do
    echo "wait $command for profile $profile_to_wait attempt number: $i, $(date)"
    aws --profile $profile_to_wait s3api wait $command --bucket $bucket_name_to_wait $key_argument 2>&1 || echo falhou $i
  done
  echo "last wait $command for profile $profile_to_wait, $(date)"
  aws --profile $profile_to_wait s3api wait $command --bucket $bucket_name_to_wait $key_argument
}

Describe 'Verificar a existência do bucket'
  setup(){
    bucket_name="test-094-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "bucket exists on profile $1 using client $2" id:"094"
    profile=$1
    client=$2
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3" | "rclone" | "mgc")
    start_time=$(date +%s)
    wait_command bucket-exists "$profile" "$bucket_name-$client"
    end_time=$(date +%s)
    bucket_exists_time=$((end_time - start_time))
      ;;
    esac
    echo "Tempo para verificar a existência do bucket no perfil $profile com $client: $bucket_exists_time" >> ./report/results-benchmark.tap
    rclone purge $profile:$bucket_name-$client > /dev/null
  End
End

Describe 'Verificar a existência do objeto'
  setup(){
    bucket_name="test-094-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "bucket exists on profile $1 using client $2" id:"094"
    profile=$1
    client=$2
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3" | "rclone" | "mgc")
    start_time=$(date +%s)
    wait_command object-exists "$profile" "$bucket_name-$client" "$file1_name"
    end_time=$(date +%s)
    object_exists_time=$((end_time - start_time))
      ;;
    esac
    echo "Tempo para verificar a existência do objeto no perfil $profile com $client: $object_exists_time" >> ./report/results-benchmark.tap
    rclone purge $profile:$bucket_name-$client > /dev/null
  End
End

Describe 'Verificar a existência do bucket publico'
  setup(){
    bucket_name="test-094-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "bucket exists on profile $1-second using client $2" id:"094"
    profile=$1
    client=$2
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client --acl public-read > /dev/null
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3" | "rclone" | "mgc")
    start_time=$(date +%s)
    wait_command bucket-exists "$profile-second" "$bucket_name-$client"
    end_time=$(date +%s)
    bucket_exists_time=$((end_time - start_time))
      ;;
    esac
    echo "Tempo para verificar existência do bucket publico no perfil $profile-second com $client: $bucket_exists_time" >> ./report/results-benchmark.tap
    rclone purge $profile:$bucket_name-$client > /dev/null
  End
End

Describe 'Verificar a existência do objeto publico'
  setup(){
    bucket_name="test-094-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "bucket exists on profile $1-second using client $2" id:"094"
    profile=$1
    client=$2
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3" | "rclone" | "mgc")
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client --acl public-read > /dev/null
    start_time=$(date +%s)
    wait_command object-exists "$profile-second" "$bucket_name-$client" "$file1_name"
    end_time=$(date +%s)
    object_exists_time=$((end_time - start_time))
      ;;
    esac
    echo "Tempo para verificar a existência do objeto publico no perfil $profile-second com $client: $object_exists_time" >> ./report/results-benchmark.tap
    rclone purge $profile:$bucket_name-$client > /dev/null
  End
End

############

Describe 'Verificar a inexistência do bucket vazio após deletar'
  setup(){
    bucket_name="test-094-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "bucket exists on profile $1 using client $2" id:"094"
    profile=$1
    client=$2
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3 rb s3://$bucket_name-$client > /dev/null
    start_time=$(date +%s)
    wait_command bucket-not-exists "$profile" "$bucket_name-$client"
    end_time=$(date +%s)
    bucket_exists_time=$((end_time - start_time))
      ;;
    "rclone")
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    rclone purge $profile:$bucket_name-$client > /dev/null
    start_time=$(date +%s)
    wait_command bucket-not-exists "$profile" "$bucket_name-$client"
    end_time=$(date +%s)
    bucket_exists_time=$((end_time - start_time))
      ;;
    "mgc")
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    mgc profile set $profile > /dev/null
    mgc object-storage buckets delete "$bucket_name-$client" --recursive --no-confirm > /dev/null
    start_time=$(date +%s)
    wait_command bucket-not-exists "$profile" "$bucket_name-$client"
    end_time=$(date +%s)
    bucket_exists_time=$((end_time - start_time))
      ;;
    esac
    echo "Tempo para verificar a inexistência do bucket vazio deletado no perfil $profile com $client: $bucket_exists_time" >> ./report/results-benchmark.tap
    End
End

Describe 'Verificar a inexistência do objeto deletado'
  setup(){
    bucket_name="test-094-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "bucket exists on profile $1 using client $2" id:"094"
    profile=$1
    client=$2
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client > /dev/null
    wait_command object-exists "$profile" "$bucket_name-$client" "$file1_name"
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    aws --profile $profile s3 rm s3://$bucket_name-$client/$file1_name > /dev/null
    start_time=$(date +%s)
    wait_command object-not-exists "$profile" "$bucket_name-$client" "$file1_name"
    end_time=$(date +%s)
    object_exists_time=$((end_time - start_time))
      ;;
    "rclone")
    rclone delete $profile:$bucket_name-$client/$file1_name > /dev/null
    start_time=$(date +%s)
    wait_command object-not-exists "$profile" "$bucket_name-$client" "$file1_name"
    end_time=$(date +%s)
    object_exists_time=$((end_time - start_time))
      ;;
    "mgc")
    mgc object-storage objects delete $bucket_name-$client/$file1_name --no-confirm > /dev/null
    start_time=$(date +%s)
    wait_command object-not-exists "$profile" "$bucket_name-$client" "$file1_name"
    end_time=$(date +%s)
    object_exists_time=$((end_time - start_time))
      ;;
    esac
    echo "Tempo para verificar a inexistência do objeto deletado no perfil $profile com $client: $object_exists_time" >> ./report/results-benchmark.tap
    rclone purge $profile:$bucket_name-$client > /dev/null
  End
End

Describe 'Verificar a inexistência do bucket publico deletado'
  setup(){
    bucket_name="test-094-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "bucket exists on profile $1-second using client $2" id:"094"
    profile=$1
    client=$2
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client --acl public-read > /dev/null
    wait_command bucket-exists "$profile-second" "$bucket_name-$client"
    aws --profile $profile s3 rb s3://$bucket_name-$client  > /dev/null
    start_time=$(date +%s)
    wait_command bucket-not-exists "$profile-second" "$bucket_name-$client"
    end_time=$(date +%s)
    bucket_exists_time=$((end_time - start_time))
    echo "Tempo para verificar a inexistência do bucket publico deletado no perfil $profile-second: $bucket_exists_time" >> ./report/results-benchmark.tap
      ;;
    "rclone")
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client --acl public-read > /dev/null
    wait_command bucket-exists "$profile-second" "$bucket_name-$client"
    rclone rmdir $profile:$bucket_name-$client  > /dev/null
    start_time=$(date +%s)
    wait_command bucket-not-exists "$profile-second" "$bucket_name-$client"
    end_time=$(date +%s)
    bucket_exists_time=$((end_time - start_time))
      ;;
    "mgc")
    aws --profile $profile s3api create-bucket --bucket $bucket_name-$client --acl public-read > /dev/null
    wait_command bucket-exists "$profile-second" "$bucket_name-$client"
    mgc profile set $profile > /dev/null
    mgc object-storage buckets delete "$bucket_name-$client" --recursive --no-confirm > /dev/null
    start_time=$(date +%s)
    wait_command bucket-not-exists "$profile-second" "$bucket_name-$client"
    end_time=$(date +%s)
    bucket_exists_time=$((end_time - start_time))
      ;;
    esac
    echo "Tempo para verificar a inexistência do bucket publico deletado no perfil $profile-second com $client: $bucket_exists_time" >> ./report/results-benchmark.tap
  End
End

Describe 'Verificar a inexistência do objeto publico deletado'
  setup(){
    bucket_name="test-094-$(date +%s)"
    file1_name="LICENSE"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "bucket exists on profile $1-second using client $2" id:"094"
    profile=$1
    client=$2
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client --acl public-read > /dev/null
    wait_command object-exists "$profile-second" "$bucket_name-$client" "$file1_name"
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    aws --profile $profile s3 rm s3://$bucket_name-$client/$file1_name > /dev/null
    start_time=$(date +%s)
    wait_command object-not-exists "$profile-second" "$bucket_name-$client" "$file1_name"
    end_time=$(date +%s)
    object_exists_time=$((end_time - start_time))
      ;;
    "rclone")
    rclone delete $profile:$bucket_name-$client/$file1_name > /dev/null
    start_time=$(date +%s)
    wait_command object-not-exists "$profile-second" "$bucket_name-$client" "$file1_name"
    end_time=$(date +%s)
    object_exists_time=$((end_time - start_time))
      ;;
    "mgc")
    mgc profile set $profile > /dev/null
    mgc object-storage objects delete "$bucket_name-$client/$file1_name" --no-confirm > /dev/null
    start_time=$(date +%s)
    wait_command object-not-exists "$profile-second" "$bucket_name-$client" "$file1_name"
    end_time=$(date +%s)
    object_exists_time=$((end_time - start_time))
      ;;
    esac
    echo "Tempo para verificar a inexistência do objeto publico deletado no perfil $profile-second com $client: $object_exists_time" >> ./report/results-benchmark.tap
    rclone purge $profile:$bucket_name-$client > /dev/null
  End
End


#tempo para upload 1gb
Describe 'Tempo para upload 1gb'
  setup(){
    bucket_name="test-094-$(date +%s)"
    file1_name="1gb"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "Tempo para upload $1 using client $2" id:"094"
    profile=$1
    client=$2
    fallocate -l 1gb 1gb    
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    start_time=$(date +%s)
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client > /dev/null
    end_time=$(date +%s)
    wait_command object-exists "$profile" "$bucket_name-$client" "$file1_name"
    aws --profile $profile s3 rm s3://$bucket_name-$client/$file1_name > /dev/null
    wait_command object-not-exists "$profile" "$bucket_name-$client" "$file1_name"
    object_exists_time=$((end_time - start_time))
    echo "Tempo para upload $file1_name no perfil $profile com $client: $object_exists_time" >> ./report/results-benchmark.tap
    rclone purge $profile:$bucket_name-$client > /dev/null
      ;;
    "rclone")
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    start_time=$(date +%s)
    rclone copy $file1_name $profile:$bucket_name-$client > /dev/null
    end_time=$(date +%s)
    wait_command object-exists "$profile" "$bucket_name-$client" "$file1_name"
    aws --profile $profile s3 rm s3://$bucket_name-$client/$file1_name > /dev/null
    wait_command object-not-exists "$profile" "$bucket_name-$client" "$file1_name"
    object_exists_time=$((end_time - start_time))
    echo "Tempo para upload $file1_name no perfil $profile com $client: $object_exists_time" >> ./report/results-benchmark.tap
    rclone purge $profile:$bucket_name-$client > /dev/null
      ;;
    "mgc")
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    mgc profile set $profile /dev/null
    start_time=$(date +%s)
    mgc object-storage objects upload $file1_name --dst $bucket_name-$client > /dev/null
    end_time=$(date +%s)
    wait_command object-exists "$profile" "$bucket_name-$client" "$file1_name"
    aws --profile $profile s3 rm s3://$bucket_name-$client/$file1_name > /dev/null
    wait_command object-not-exists "$profile" "$bucket_name-$client" "$file1_name"
    object_exists_time=$((end_time - start_time))
    echo "Tempo para upload 1gb no perfil $profile com $client: $object_exists_time" >> ./report/results-benchmark.tap
    rclone purge $profile:$bucket_name-$client > /dev/null
      ;;
    esac
  End
End
#tempo para upload 2gb
Describe 'Tempo para upload 2gb'
  setup(){
    bucket_name="test-094-$(date +%s)"
    file1_name="2gb"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "Tempo para upload $1 using client $2" id:"094"
    profile=$1
    client=$2
    fallocate -l 2gb 2gb
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    start_time=$(date +%s)
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client  > /dev/null
    end_time=$(date +%s)
    wait_command object-exists "$profile" "$bucket_name-$client" "$file1_name"
    aws --profile $profile s3 rm s3://$bucket_name-$client/$file1_name > /dev/null
    wait_command object-not-exists "$profile" "$bucket_name-$client" "$file1_name"
    object_exists_time=$((end_time - start_time))
    echo "Tempo para upload $file1_name no perfil $profile com $client: $object_exists_time" >> ./report/results-benchmark.tap
    rclone purge $profile:$bucket_name-$client > /dev/null
      ;;
    "rclone")
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    start_time=$(date +%s)
    rclone copy $file1_name $profile:$bucket_name-$client > /dev/null
    end_time=$(date +%s)
    wait_command object-exists "$profile" "$bucket_name-$client" "$file1_name"
    aws --profile $profile s3 rm s3://$bucket_name-$client/$file1_name > /dev/null
    wait_command object-not-exists "$profile" "$bucket_name-$client" "$file1_name"
    object_exists_time=$((end_time - start_time))
    echo "Tempo para upload $file1_name no perfil $profile com $client: $object_exists_time" >> ./report/results-benchmark.tap
    rclone purge $profile:$bucket_name-$client > /dev/null
      ;;
    "mgc")
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    mgc profile set $profile /dev/null
    start_time=$(date +%s)
    mgc object-storage objects upload $file1_name --dst $bucket_name-$client > /dev/null
    end_time=$(date +%s)
    wait_command object-exists "$profile" "$bucket_name-$client" "$file1_name"
    aws --profile $profile s3 rm s3://$bucket_name-$client/$file1_name > /dev/null
    wait_command object-not-exists "$profile" "$bucket_name-$client" "$file1_name"
    object_exists_time=$((end_time - start_time))
    echo "Tempo para upload $file1_name no perfil $profile com $client: $object_exists_time" >> ./report/results-benchmark.tap
    rclone purge $profile:$bucket_name-$client > /dev/null
      ;;
    esac
  End
End
#tempo para download 1gb
Describe 'Tempo para download 1gb'
  setup(){
    bucket_name="test-094-$(date +%s)"
    file1_name="1gb"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "Tempo para download $1 using client $2" id:"094"
    profile=$1
    client=$2
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client > /dev/null
    start_time=$(date +%s)
    aws --profile $profile s3 cp s3://$bucket_name-$client/$file1_name . > /dev/null
    end_time=$(date +%s)
    wait_command object-exists "$profile" "$bucket_name-$client" "$file1_name"
    aws --profile $profile s3 rm s3://$bucket_name-$client/$file1_name > /dev/null
    wait_command object-not-exists "$profile" "$bucket_name-$client" "$file1_name"
    object_exists_time=$((end_time - start_time))
    echo "Tempo para download $file1_name no perfil $profile: $object_exists_time" >> ./report/results-benchmark.tap
    rclone purge $profile:$bucket_name-$client > /dev/null
      ;;
    "rclone")
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client > /dev/null
    start_time=$(date +%s)
    rclone copy $profile:$bucket_name-$client/$file1_name ./$file1_name-$bucket_name > /dev/null
    end_time=$(date +%s)
    wait_command object-exists "$profile" "$bucket_name-$client" "$file1_name"
    aws --profile $profile s3 rm s3://$bucket_name-$client/$file1_name > /dev/null
    wait_command object-not-exists "$profile" "$bucket_name-$client" "$file1_name"
    object_exists_time=$((end_time - start_time))
    echo "Tempo para download $file1_name no perfil $profile: $object_exists_time" >> ./report/results-benchmark.tap
    rclone purge $profile:$bucket_name-$client > /dev/null
      ;;
    "mgc")
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client > /dev/null
    start_time=$(date +%s)
    mgc object-storage objects download --src $bucket_name-$client/$file1_name --dst $file1_name-$bucket_name > /dev/null
    rclone copy $profile:$bucket_name-$client/$file1_name ./$file1_name-$bucket_name > /dev/null
    end_time=$(date +%s)
    wait_command object-exists "$profile" "$bucket_name-$client" "$file1_name"
    aws --profile $profile s3 rm s3://$bucket_name-$client/$file1_name > /dev/null
    wait_command object-not-exists "$profile" "$bucket_name-$client" "$file1_name"
    object_exists_time=$((end_time - start_time))
    echo "Tempo para download $file1_name no perfil $profile: $object_exists_time" >> ./report/results-benchmark.tap
    rclone purge $profile:$bucket_name-$client > /dev/null
      ;;
    esac
  End
End
#tempo para download 2gb
Describe 'Tempo para download 2gb'
  setup(){
    bucket_name="test-094-$(date +%s)"
    file1_name="2gb"
  }
  Before 'setup'
  Parameters:matrix
    $PROFILES
    $CLIENTS
  End
  Example "Tempo para download $1 using client $2" id:"094"
    profile=$1
    client=$2
    case "$client" in
    "aws-s3api" | "aws" | "aws-s3")
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client > /dev/null
    start_time=$(date +%s)
    aws --profile $profile s3 cp s3://$bucket_name-$client/$file1_name . > /dev/null
    end_time=$(date +%s)
    wait_command object-exists "$profile" "$bucket_name-$client" "$file1_name"
    aws --profile $profile s3 rm s3://$bucket_name-$client/$file1_name > /dev/null
    wait_command object-not-exists "$profile" "$bucket_name-$client" "$file1_name"
    object_exists_time=$((end_time - start_time))
    echo "Tempo para download $file1_name no perfil $profile: $object_exists_time" >> ./report/results-benchmark.tap
    rclone purge $profile:$bucket_name-$client > /dev/null
      ;;
    "rclone")
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client > /dev/null
    start_time=$(date +%s)
    rclone copy $profile:$bucket_name-$client/$file1_name ./$file1_name-$bucket_name > /dev/null
    end_time=$(date +%s)
    wait_command object-exists "$profile" "$bucket_name-$client" "$file1_name"
    aws --profile $profile s3 rm s3://$bucket_name-$client/$file1_name > /dev/null
    wait_command object-not-exists "$profile" "$bucket_name-$client" "$file1_name"
    object_exists_time=$((end_time - start_time))
    echo "Tempo para download $file1_name no perfil $profile: $object_exists_time" >> ./report/results-benchmark.tap
    rclone purge $profile:$bucket_name-$client > /dev/null,
      ;;
    "mgc")
    aws --profile $profile s3 mb s3://$bucket_name-$client > /dev/null
    aws --profile $profile s3 cp $file1_name s3://$bucket_name-$client > /dev/null
    start_time=$(date +%s)
    mgc object-storage objects download --src $bucket_name-$client/$file1_name --dst $file1_name-$bucket_name > /dev/null
    rclone copy $profile:$bucket_name-$client/$file1_name ./$file1_name-$bucket_name > /dev/null
    end_time=$(date +%s)
    wait_command object-exists "$profile" "$bucket_name-$client" "$file1_name"
    aws --profile $profile s3 rm s3://$bucket_name-$client/$file1_name > /dev/null
    wait_command object-not-exists "$profile" "$bucket_name-$client" "$file1_name"
    object_exists_time=$((end_time - start_time))
    echo "Tempo para download $file1_name no perfil $profile: $object_exists_time" >> ./report/results-benchmark.tap
    rclone purge $profile:$bucket_name-$client > /dev/null
      ;;
    esac
  End
End
