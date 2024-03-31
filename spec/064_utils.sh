create_bucket(){
  profile=$1
  client=$2
  bucket_name=$3

  case "$client" in
  "aws-s3api" | "aws")
    aws s3api create-bucket --bucket "$bucket_name" --profile "$profile" ;;
  "rclone")
    rclone mkdir "$profile:$bucket_name" ;;
  "mgc")
    mgc profile set-current $profile > /dev/null
    mgc object-storage buckets create "$bucket_name" ;;
  esac
}
create_bucket_success_output(){
  profile=$1
  client=$2
  bucket_name=$3

  case "$client" in
  "aws-s3api" | "aws")
    echo "\"Location\": \"/$bucket_name\"" ;;
  "rclone")
    echo "" ;;
  "mgc")
    echo "Created bucket $bucket_name" ;;
  esac
}
enable_versioning(){
  profile=$1
  client=$2
  bucket_name=$3

  case "$client" in
  "aws-s3api" | "aws")
    aws s3api put-bucket-versioning --bucket "$bucket_name" --profile "$profile" --versioning-configuration Status=Enabled ;;
  "rclone")
    rclone backend versioning "$profile:$bucket_name" Enabled ;;
  "mgc")
    mgc profile set-current $profile > /dev/null
    mgc object-storage buckets versioning enable --bucket "$bucket_name" ;;
  esac
}
enable_versioning_success_output(){
  profile=$1
  client=$2
  bucket_name=$3

  case "$client" in
  "aws-s3api" | "aws")
    echo "" ;;
  "rclone")
    echo "Enabled" ;;
  "mgc")
    echo "Enabled versioning for $bucket_name" ;;
  esac
}
put_object(){
  profile=$1
  client=$2
  bucket_name=$3
  local_file=$4
  key=$5

  case "$client" in
  "aws-s3api" | "aws")
    aws --profile $profile s3api put-object --bucket $bucket_name --body $local_file --key $key ;;
  "rclone")
    rclone copyto $local_file $profile:$bucket_name/$key --no-check-dest ;;
  "mgc")
    mgc profile set-current $profile > /dev/null
    mgc object-storage objects upload --src="$local_file" --dst="$bucket_name/$key"
    echo "" ;;
  esac
}
put_object_success_output(){
  profile=$1
  client=$2
  bucket_name=$3
  local_file=$4
  key=$5

  case "$client" in
  "aws-s3api" | "aws")
    echo "ETag" ;;
  "rclone")
    echo "" ;;
  "mgc")
    echo "Uploaded file $local_file to $bucket_name/$key"
  esac
}
list_object_versions(){
  profile=$1
  client=$2
  bucket_name=$3
  case "$client" in
  "aws-s3api" | "aws")
    aws --profile $profile s3api list-object-versions --bucket $bucket_name --query Versions ;;
  "rclone")
    rclone --s3-versions ls $profile:$bucket_name ;;
  "mgc")
    mgc profile set-current $profile > /dev/null
    mgc object-storage objects versions --dst="$bucket_name" --cli.output json;;
  esac
}
list_object_versions_success_output(){
  profile=$1
  client=$2
  bucket_name=$3
  key=$4
  case "$client" in
  "aws-s3api" | "aws")
    echo "\"Key\": \"$key\",";;
  "rclone")
    echo "$key-v";;
  "mgc")
    echo "\"Key\": \"$key\",";;
  esac
}
