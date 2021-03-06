### What is `copier`
- This is a script written in node JS to create a folder in S3 bucket and copy all the artefacts from other source folder.

#### When will it be used
- Mainly before each release, we will create a folder in `stable` s3 bucket with the release number and copy all the artefacts from the previous release folder.

#### Dependencies
- Need to install `aws-sdk` using the below command
```
  $ npm install aws-sdk̨
```
- For AWS S3 access, keep your AWS credentials data in a shared file on Mac(~/.aws/credentials). e.g.
```
[default]
aws_access_key_id = <YOUR_ACCESS_KEY_ID>
aws_secret_access_key = <YOUR_SECRET_ACCESS_KEY>
```

#### How to run
- Modify the source folder name and destination folder name before the release in `copier.js` file
Sample is shown below:
```
const sourceFolder = 'msf-release-a.b.c';   // source folder name
const destinationFolder = 'msf-release-x.y.x'; // new destination folder
```
- Run the below command to copy all the artefacts from source release folder to destination release folder:
```
  $ node copier.js
```
