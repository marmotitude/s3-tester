#!/bin/env bash
function usage() {
    echo $1
    echo "Usage: clear_buckets -n <test_number> -p <profile>"
    echo "WARN: Since aws listing is paginated, this script may need to be run multiple times"
}

re='^[0-9]+$'
while getopts ":n:p:" config
do
    case "$config" in
    n)
        [[ ! $OPTARG =~ $re ]] && usage "$OPTARG is not a number" && exit 1
        test_n=$(printf "%03d" $OPTARG)
    ;;
    p)
        [ -z "$OPTARG" ] && usage "$OPTARG should be a string" && exit 1
        profile="$OPTARG"
    ;;
    ?)
        echo "Unknown flag $config"
        usage
        exit 1
    ;;
    esac
done

# both variables should be set
[ ! -v test_n ] || [ ! -v profile ] && usage "Please provide both test_number and profile" && exit 1

echo "Deleting buckets matching 'test-$test_n-*' in profile $profile"

buckets=$(aws --profile $profile s3 ls \
| cut -d " " -f 3 \
| grep "test-$test_n-*")
echo "$buckets"
read -p "Delete buckets listed? [yN]: " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && echo "aborting" && exit
set -x
for bucket in $buckets; do
    aws --profile "$profile" s3api delete-bucket-policy --bucket "$bucket"
    aws --profile "$profile" s3 rm "s3://$bucket" --recursive
    aws --profile "$profile" s3 rb "s3://$bucket"
done
