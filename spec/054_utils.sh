# creates a zero filled file of ${1} GB on the tmp dir and sets path to $local_file variable
create_file_gb(){
  size_gb=$1
  local_file="/tmp/${size_gb}GB_file"
  if [ -f "$local_file" ]; then
    echo "File $local_file exists"
  else
    echo "creating $local_file..."
    fallocate -l ${size_gb}gb $local_file
    echo "...$local_file created."
  fi
}

setup_54(){
  create_file_gb $1
  setup
}
