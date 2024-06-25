# s3-tester
Compatibility tests for AWS S3 object-storage providers.
A reboot of https://github.com/marmotitude/object-storage-tests

## Usage

> :warning: **See allso:** [Github Workflown Usage](.github/workflows/README.md) and [Docker Image Usage](./oci/README.md).


### Shellspec (cli tools)

```
# use profiles: do-nyc and aws-east
# to run tests: 011 (List Buckets), 053 (Upload Files) and 061 (List Objects)
# with only the aws-cli client and passing --fail-fast to shellspec

./bin/test.sh --profiles do-nyc,aws-east --clients aws --tests 11,53,61 -- --fail-fast
```

The tests assumes that you have configured all cli tools (aws-cli, rclone and mgc) with the same
profile names. And tests like the ACL ones that needs 2 profiles uses a convention of the second
one being named `<name-of-one-profile>-second`.

### Bun Test (aws-sdk-js)

```
# use profiles: br-ne1 and br-se1
# to run all tests from spec/js/*.test.ts
# passing additional bun test arguments after -- (double dash)

./bin/js-test.sh --profiles br-ne1,br-se1 -- --bail
```

#### Profiles (optional)

To make the process of setting multiple profiles on multiple tools less manual, 
there is a shell script that replaces existing config files with new ones created using data
from a single `profiles.yaml` generic config, use `profiles.example.yaml` as an example:

```
./bin/replace_configs.sh
```

## License

MIT

## Tests

Below is a list of proposed tests to run against S3-compatible object storage providers in order to
check compatibility between those providers and existing S3 clients.

As of March 2024, most of them are unimplemented, so consider this table a TODO list, it's here to
make it easy to reference specific human-readable descriptions to a test number.

|Test ID | Category |Test Description |Implementation |
|--------|----------|-----------------|-------|
| 001 | Bucket Management|Create Bucket| aws-s3api, aws-s3, rclone |
| 002 | Bucket Management|Create Bucket with name with space|  aws-s3api, aws-s3, rclone |
| 003 | Bucket Management|Create Bucket with name with just letters| REVIEW |
| 004 | Bucket Management|Create Bucket with name with just letters in Uppercase|  aws-s3api, aws-s3, rclone |
| 005 | Bucket Management|Create Bucket with name with just letters in Lowercase|  aws-s3api, aws-s3, rclone |
| 006 | Bucket Management|Create Bucket with name with just numbers|  aws-s3api, aws-s3, rclone |
| 007 | Bucket Management|Create Bucket with name with just special characters|  aws-s3api, aws-s3, rclone |
| 008 | Bucket Management|Create Bucket with combination of letters and numbers|  aws-s3api, aws-s3, rclone |
| 009 | Bucket Management|Try to create Bucket with low than 3 characters in the name|  aws-s3api, aws-s3, rclone |
| 010 | Bucket Management|Try to create bucket with high than 64 characters in the name|  aws-s3api, aws-s3, rclone |
|||||
| 011 | Bucket Management|List Buckets| |
|||||
| 012 | Bucket Management|Verify the number of objects| |
| 013 | Bucket Management|Verify the informations in the list| |
| 014 | Bucket Management|Verify the size of buckets| |
|||||
| 015 | Bucket Management|Delete Buckets empty| |
| 016 | Bucket Management|Delete Buckets with Objects| |
| 017 | Bucket Management|Delete buckets in batch| |
|||||
| 018 | Bucket Permission|Create public bucket| |
| 019 | Bucket Permission|Access the public bucket and check the list of objects| |
| 020 | Bucket Permission|Access the public bucket and check the access of objects| |
| 021 | Bucket Permission|Create private bucket| |
| 022 | Bucket Permission|Access the private bucket and check the list of objects| |
| 023 | Bucket Permission|Create a ACL read for a bucket | |
| 024 | Bucket Permission|Access the Private with ACL bucket with and check the list of objects| |
| 025 | Bucket Permission|Access the Private with ACL bucket and check the access of objects| |
| 026 | Bucket Permission|Create a ACL read/write for a bucket | |
| 027 | Bucket Permission|Create ACL in a batch for more than 2 ppl with option of R and R/W differents| |
| 028 | Bucket Permission|Access the Private with ACL bucket with and check the list of objects| |
| 029 | Bucket Permission|Access the Private with ACL bucket and check the access of objects| |
| 030 | Bucket Permission|Delete public bucket| |
| 031 | Bucket Permission|Delete private bucket| |
| 032 | Bucket Permission|Delete private with ACL bucket| |
|||||
| 033 | Bucket Sharing|Copy URL for public buckets| |
| 034 | Bucket Sharing|Validate the URL for public buckets| |
| 035 | Bucket Sharing|Set a presigned URL for a private bucket| |
| 036 | Bucket Sharing|Validate the URL of presigned| |
| 037 | Bucket Sharing|Set a presigned URL for a private with ACL bucket| |
| 038 | Bucket Sharing|Validate the URL of presigned for the ACL bucket| |
|||||
| 039 | Object Versioning|Set the versioning for a public bucket| |
| 040 | Object Versioning|Set the versioning for a private bucket| |
| 041 | Object Versioning|Set the versioning for a bucket with ACL| |
| 042 | Object Versioning|Upload object to versioning in the public bucket| |
| 043 | Object Versioning|Upload object to versioning in the private bucket| |
| 044 | Object Versioning|Upload object to versioning in the private ACL bucket| |
| 045 | Object Versioning|Download object to versioning in the public bucket| |
| 046 | Object Versioning|Donwload object to versioning in the private bucket| |
| 047 | Object Versioning|Download object to versioning in the private ACL bucket| |
| 048 | Object Versioning|Delete Bucket versioned| |
| 049 | Object Versioning|Delete object with versions| |
| 050 | Object Versioning|Delete bucket with objects with versions| |
| 051 | Object Versioning|Delete versions| |
| 052 | Object Versioning|Delete versions in batch| |
|||||
| 053 | Object Management|Upload Files| aws-s3api, aws-s3, rclone, mgc |
| 054 | Object Management|Upload Files of 1GB| aws-s3api, aws-s3, rclone, mgc |
| 055 | Object Management|Upload Files of 5GB| aws-s3api, aws-s3, rclone, mgc |
| 056 | Object Management|Upload Files of 10GB| aws-s3api, aws-s3, rclone, mgc |
| 057 | Object Management|Download Files| aws-s3api, aws-s3, rclone, mgc |
| 058 | Object Management|Download Files of 1GB| aws-s3api, aws-s3, rclone, mgc |
| 059 | Object Management|Download Files of 5GB| aws-s3api, aws-s3, rclone, mgc |
| 060 | Object Management|Download Files of 10GB| aws-s3api, aws-s3, rclone, mgc |
| 061 | Object Management|List Objects| aws-s3api, aws-s3, rclone, mgc |
| 062 | Object Management|Delete Objects| aws-s3api, aws-s3, rclone, mgc |
| 063 | Object Management|Delete objects in batch| aws-s3api, aws-s3, rclone, mgc |
| 064 | Object Management|Delete object veresioned| aws-s3api, aws-s3, rclone, mgc |
| 065 | Object Management|Pause upload of multiparts| |
| 066 | Object Management|Pause download of multiparts| |
| 067 | Object Management|Abort upload of multiparts| |
| 068 | Object Management|Abort download of multiparts| |
| 069 | Object Management|Resume upload of multiparts| |
| 070 | Object Management|Resume download of multiparts| |
| 071 | Object Management|Delete parts of incomplete objects| |
|||||
| 072 | Authorization|Create an API Key| REVIEW |
| 073 | Authorization|Create an API Key in a delegated account| REVIEW |
| 074 | Authorization|Validate authorization using API Key| REVIEW |
| 075 | Authorization|Validate authorization by delegation| REVIEW |
| 076 | Authorization|Revogate an API Key| REVIEW |
| 077 | Authorization|Validate authorization using API Key| REVIEW |
| 078 | Authorization|Create a new account and create a new api key| REVIEW |
| 079 | Authorization|Validate authorization using API Key of new accounts| REVIEW |
|||||
| 080 | Security and compliance|Validate criptography| REVIEW |
| 081 | Security and compliance|Validate Takedown process| REVIEW |
|||||
| 082 | Metering|Validate metering of storage in GB/h| REVIEW |
| 083 | Metering|Validate metering of egress transfer in GB| REVIEW |
|||||
| 084 | Cold Storage | Upload object using storage class | NEW |
| 085 | Cold Storage | List object includes storage class | NEW |
| 086 | Cold Storage | Multipart upload with storage class | PENDING |
| 087 | Cold Storage | Change the storage class of an object (copy to same bucket with same key, but different storage class) | PENDING |

## Acknowledgements

- [ShellSpec](https://github.com/shellspec/shellspec)
- [argparse-sh](https://github.com/yaacov/argparse-sh)

