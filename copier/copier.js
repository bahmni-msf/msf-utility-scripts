// Load the AWS SDK for Node.js
var AWS = require('aws-sdk');
// Set the region
AWS.config.update({region: 'ap-south-1'});

// Create S3 service object
s3 = new AWS.S3({apiVersion: '2006-03-01'});


const bucketName = 'stable';        // parent bucket name
const sourceFolder = 'msf-release-a.b.c';   // source folder name
const destinationFolder = 'msf-release-x.y.x'; // new destination folder

(async function() {
  try {
    const listObjectsResponse = await s3.listObjects({
        Bucket: bucketName,
        Prefix: `${sourceFolder}/`,
        Delimiter: '/',
    }).promise();

    const folderContentInfo = listObjectsResponse.Contents;
    const folderPrefix = listObjectsResponse.Prefix;

    await Promise.all(
      folderContentInfo.map(async (fileInfo) => {
        console.log(`Copying file ${fileInfo.Key} to ${destinationFolder} folder`);
        await s3.copyObject({
          Bucket: bucketName,
          CopySource: `${bucketName}/${fileInfo.Key}`,
          Key: `${destinationFolder}/${fileInfo.Key.replace(folderPrefix, '')}`,
        }).promise();

      })
    );
} catch (err) {
  console.error(err); // error handling
}
})();
