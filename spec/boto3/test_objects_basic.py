# make sure there is an AWS_PROFILE env var set and a configured aws profile with the name
import boto3

def test_list_buckets():
    s3 = boto3.client('s3')
    response = s3.list_buckets()
    assert('Buckets' in response)

if __name__ == "__main__":
    pytest.main([__file__])
