# creates a zero filled file of ${1} GB on the tmp dir and sets path to $local_file variable
create_file(){
  size=$1
  unit=$2
  filename="${size}${unit}_file"
  local_dir="/tmp"
  local_file="${local_dir}/${filename}"
  if [ -f "$local_file" ]; then
    echo "File $local_file exists"
  else
    echo "creating $local_file..."
    fallocate -l "${size}${unit}" "$local_file"
    echo "...$local_file created."
  fi
}
