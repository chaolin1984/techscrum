const AWS = require('aws-sdk');
const s3 = new AWS.S3();

exports.handler = async (event, context) => {
  
console.log('Received event:', JSON.stringify(event));
  
  const sourceBucket = "techscrum-frontend-jr10";
  const destinationBucket = "techscrum-s3-backup-serverless";

  try {
    // Get a list of all objects in the source bucket
    const listObjectsParams = {
      Bucket: sourceBucket,
    };
    const sourceObjects = await s3.listObjectsV2(listObjectsParams).promise();

    // Loop through each object and copy it to the destination bucket
    for (const obj of sourceObjects.Contents) {
      const copyParams = {
        Bucket: destinationBucket,
        CopySource: `${sourceBucket}/${obj.Key}`,
        Key: obj.Key,
      };
      await s3.copyObject(copyParams).promise();
    }

    return {
      statusCode: 200,
        body: JSON.stringify({ message: 'All objects copied successfully!' })
    };
  } catch (error) {
    console.error('Error copying objects:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Error copying objects' })
    };
  }
};
