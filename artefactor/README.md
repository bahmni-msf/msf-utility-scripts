### What is `artefactor`
- This is a script written in node JS to find out the latest artefacts (omods, rpms, zip) of different MSF Bahmni modules.
- This code will check the `latest` folder of each modules in the respective S3 buckets to find out the latest artefacts with the version.

#### When will it be used
- Mainly after each sprint, we should run this to have the list of latest artefacts of different modules for that sprint. This will be used for any future reference or if we test some older feature at any point of time.

#### Dependencies
- Need to install `aws-sdk` using the below command
```
  $ npm install aws-sdk
```

#### How to run
- Add all the modules S3 bucket name in `moduleList.js` file. Ideally the bucket name should be same as the github repo name.
Sample is shown below:
```
var msfmodules = [
  "bahmni-mart",
  "implementer-interface"
]
```
- Run the below command:
```
  $ node artefacts.js
```
- Output will be in the below format
```
  List of Latest Artefacts on Mon Apr 20 2020 13:21:45 GMT+0530 (India Standard Time)
  -------------------------------------------------------------------------------------------------
  1) bahmni-mart: bahmni-mart-2.0.3-72.noarch.rpm
  2) implementer-interface: bahmni-implementer-interface-91-60.noarch.rpm

```
