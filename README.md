# s3-tester
Compatibility tests for AWS S3 object-storage providers. A reboot of https://github.com/marmotitude/object-storage-tests

|Test ID | Category |Test Description |
|--------|----------|-----------------|
| 001 | Bucket Management|Create Bucket|
| 002 | Bucket Management|Create Bucket with name with space|
| 003 | Bucket Management|Create Bucket with name with just letters|
| 004 | Bucket Management|Create Bucket with name with just letters in Uppercase|
| 005 | Bucket Management|Create Bucket with name with just letters in Lowercase|
| 006 | Bucket Management|Create Bucket with name with just numbers|
| 007 | Bucket Management|Create Bucket with name with just special characters|
| 008 | Bucket Management|Create Bucket with combination of letters and numbers|
| 009 | Bucket Management|Try to create Bucket with low than 3 characters in the name|
| 010 | Bucket Management|Try to create bucket with high than 64 characters in the name|
| 011 | Bucket Management|List Buckets|
| 012 | Bucket Management|Verify the number of objects|
| 013 | Bucket Management|Verify the informations in the list|
| 014 | Bucket Management|Verify the size of buckets|
| 015 | Bucket Management|Delete Buckets empty|
| 016 | Bucket Management|Delete Buckets with Objects|
| 017 | Bucket Management|Delete buckets in batch|
| 018 | Bucket Permission|Create public bucket|
| 019 | Bucket Permission|Access the public bucket and check the list of objects|
| 020 | Bucket Permission|Access the public bucket and check the access of objects|
| 021 | Bucket Permission|Create private bucket|
| 022 | Bucket Permission|Access the private bucket and check the list of objects|
| 023 | Bucket Permission|Create a ACL read for a bucket |
| 024 | Bucket Permission|Access the Private with ACL bucket with and check the list of objects|
| 025 | Bucket Permission|Access the Private with ACL bucket and check the access of objects|
| 026 | Bucket Permission|Create a ACL read/write for a bucket |
| 027 | Bucket Permission|Create ACL in a batch for more than 2 ppl with option of R and R/W differents|
| 028 | Bucket Permission|Access the Private with ACL bucket with and check the list of objects|
| 029 | Bucket Permission|Access the Private with ACL bucket and check the access of objects|
| 031 | Bucket Permission|Delete public bucket|
| 032 | Bucket Permission|Delete private bucket|
| 033 | Bucket Permission|Delete private with ACL bucket|
| 034 | Bucket Sharing|Copy URL for public buckets|
| 035 | Bucket Sharing|Validate the URL for public buckets|
| 036 | Bucket Sharing|Set a presigned URL for a private bucket|
| 037 | Bucket Sharing|Validate the URL of presigned|
| 038 | Bucket Sharing|Set a presigned URL for a private with ACL bucket|
| 039 | Bucket Sharing|Validate the URL of presigned for the ACL bucket|
| 040 | Object Versioning|Set the versioning for a public bucket|
| 041 | Object Versioning|Set the versioning for a private bucket|
| 042 | Object Versioning|Set the versioning for a bucket with ACL|
| 043 | Object Versioning|Upload object to versioning in the public bucket|
| 044 | Object Versioning|Upload object to versioning in the private bucket|
| 045 | Object Versioning|Upload object to versioning in the private ACL bucket|
| 046 | Object Versioning|Download object to versioning in the public bucket|
| 047 | Object Versioning|Donwload object to versioning in the private bucket|
| 048 | Object Versioning|Download object to versioning in the private ACL bucket|
| 049 | Object Versioning|Delete Bucket versioned|
| 050 | Object Versioning|Delete object with versions|
| 051 | Object Versioning|Delete bucket with objects with versions|
| 052 | Object Versioning|Delete versions|
| 053 | Object Versioning|Delete versions in batch|
| 054 | Object Management|Upload Files|
| 055 | Object Management|Upload Files of 1GB|
| 056 | Object Management|Upload Files of 5GB|
| 057 | Object Management|Upload Files of 10GB|
| 058 | Object Management|Download Files|
| 059 | Object Management|Download Files of 1GB|
| 060 | Object Management|Download Files of 5GB|
| 061 | Object Management|Download Files of 10GB|
| 061 | Object Management|List Objects|
| 063 | Object Management|Delete Objects|
| 064 | Object Management|Delete objects in batch|
| 065 | Object Management|Delete object veresioned|
| 066 | Object Management|Pause upload of multiparts|
| 067 | Object Management|Pause download of multiparts|
| 068 | Object Management|Abort upload of multiparts|
| 069 | Object Management|Abort download of multiparts|
| 070 | Object Management|Resume upload of multiparts|
| 071 | Object Management|Resume download of multiparts|
| 072 | Object Management|Delete parts of incomplete objects|
| 073 | Authorization|Create an API Key|
| 074 | Authorization|Create an API Key in a delegated account|
| 075 | Authorization|Validate authorization using API Key|
| 076 | Authorization|Validate authorization by delegation|
| 077 | Authorization|Revogate an API Key|
| 078 | Authorization|Validate authorization using API Key|
| 079 | Authorization|Create a new account and create a new api key|
| 080 | Authorization|Validate authorization using API Key of new accounts|
| 081 | Security and compliance|Validate criptography|
| 082 | Security and compliance|Validate Takedown process|
| 083 | Metering|Validate metering of storage in GB/h|
| 084 | Metering|Validate metering of egress transfer in GB|
