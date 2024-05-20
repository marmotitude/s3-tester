import { beforeAll, afterAll, describe, test, expect } from "bun:test";
import { 
  S3Client,
  ListBucketsCommand,
  CreateBucketCommand,
  DeleteBucketCommand,
  ListObjectsCommand,
  PutObjectCommand,
  GetObjectCommand,
  DeleteObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

// AWS S3 credentials and region from environment variables
const { AWS_PROFILE } = process.env;
// Create S3 client with provided credentials and region
const client = new S3Client();
const BUCKET_NAME = `test-${AWS_PROFILE}-${new Date().getTime()}`
const OBJECT_KEY = "key1"
const OBJECT_CONTENT = "This is my object's content"
const EXPIRATION_TIME = 200 // seconds

describe("Small tests", async () => {
  //setup
  beforeAll(async () => {

    const createBucketResponse = await client.send(new CreateBucketCommand({
      "Bucket": BUCKET_NAME,
    }));
    const putObjectResponse = await client.send(new PutObjectCommand({
      "Bucket": BUCKET_NAME,
      "Key": OBJECT_KEY,
      "Body": OBJECT_CONTENT,
    }));
  })
  //teardown
  afterAll(async () => {
    const deleteObjectResponse = await client.send(new DeleteObjectCommand({
      "Bucket": BUCKET_NAME,
      "Key": OBJECT_KEY,
    }));
    const deleteBucketResponse = await client.send(new DeleteBucketCommand({
      "Bucket": BUCKET_NAME,
    }));
  })

  test(`list buckets for profile ${AWS_PROFILE}`, async () => {
    const { Owner, Buckets } = await client.send(new ListBucketsCommand({}));
    expect(Owner.ID).toBeDefined()
    expect(Buckets.length).toBeGreaterThan(0)
    expect(Buckets.filter((b) => (b.Name === BUCKET_NAME)).length).toBe(1)
  });

  test(`list objects for profile ${AWS_PROFILE}`, async () => {
    const { Contents } = await client.send(new ListObjectsCommand({
      "Bucket": BUCKET_NAME,
    }));
    expect(Contents.length).toBe(1)
    expect(Contents[0].Key).toBe(OBJECT_KEY)
    expect(Contents[0].Size).toBe(OBJECT_CONTENT.length)
  });

  describe("Presign URLs", async() => {
    let signedGetUrl

    beforeAll(async () => {
      const command = new GetObjectCommand({
          Bucket: BUCKET_NAME,
          Key: OBJECT_KEY,
      });

      signedGetUrl = await getSignedUrl(client, command, { expiresIn: EXPIRATION_TIME });
    })
    test(`GET URL was generated`, () => {
      expect(signedGetUrl).toBeDefined()
    })
    test(`GET URL returns 200`, async () => {
      const objectDownloadResponse = await fetch(signedGetUrl)
      expect(objectDownloadResponse.ok).toBeTrue()
    })
  })
})

