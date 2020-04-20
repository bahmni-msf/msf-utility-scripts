var modules = require('./moduleList.js');
// Load the AWS SDK for Node.js
var AWS = require('aws-sdk');
// Set the region
AWS.config.update({region: 'ap-south-1'});

// Create S3 service object
s3 = new AWS.S3({apiVersion: '2006-03-01'});


async function listAllArtefactObjects(prefix) {
  let params = { Bucket: 'v2-artefacts' };
  if (prefix) params.Prefix = `${prefix}/latest/`;
  try{
    const response = await s3.listObjectsV2(params).promise();
    response.Contents.forEach((item, index) => {
      var a = item.Key.split('/')
        console.log(`${++index}) ${a[0]}: ${a[2]}`);
    });
  }catch(error){
    throw error;
  }
}

console.log("List of Latest Artefacts on " + new Date());
console.log("-------------------------------------------------------------------------------------------------");
modules.forEach(repo => {
  listAllArtefactObjects(repo);
})
