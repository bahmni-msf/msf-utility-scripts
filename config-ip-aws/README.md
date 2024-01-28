# msf-utility-scripts/config-ip-aws/config_ip

## Why config_ip tool
A tool to efficiently update IP addresses in AWS security groups.

## Prerequisites to Run This Tool
1. Install **jq**:
    ```bash
    brew install jq
    ```
2. Install AWS CLI:
   [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
3. Create an AWS IAM user with the following policies:
    ```json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "VisualEditor0",
                "Effect": "Allow",
                "Action": [
                    "ec2:RevokeSecurityGroupIngress",
                    "ec2:AuthorizeSecurityGroupIngress",
                    "ec2:UpdateSecurityGroupRuleDescriptionsIngress"
                ],
                "Resource": "*"
            }
        ]
    }
    ```
4. Create AWS profiles locally:
    ```bash
    aws configure
    aws configure --profile <name>
    ```
5. Setup CONFIG in the config_ip file:
    ```js
    {
        "aws_accounts": {
            "12345": { // account number[from aws]
                "jump-server": { // sg key[user wish]
                  "sg_id": "sg-1234", //Security group ID [from aws]
                  "sg_name": "Jump server", // [user wish]
                  "port_range": 22 // what port [user wish]
                },
                "lb": {
                    "sg_id": "sg-0123",
                    "sg_name": "Load Balancer",
                    "port_range": 443
                }
            },
            "01234": {
                "jump-server": {
                    "sg_id": "sg-12334",
                    "sg_name": "Jump server",
                    "port_range": 22
                }
            }
        },
        "ip_file_path": ".my_ip", //to maintain state [user wish]
        "name": "user" // to add description for ip [user wish]
    }
    ```

6. Add the current PATH of this folder to `~/.zshrc` or `~/.bashrc`.

## Features
1. Run the tool to add an IP to the configured AWS security groups:
    ```bash
    config_ip
    ```
2. `-h` | `--help`: Show all available options:
    ```bash
    config_ip --help
    ```
3. `-p` | `--profile`: Incorporate an IP address into a specific AWS account's security group:
    ```bash
    config_ip -p bahmni
    config_ip --profile bahmni
    ```
4. `-r` | `--remove-ip`: Remove an IP address from AWS security group:
    ```bash
    config_ip -r
    config_ip -p bahmni -r
    ```
5. `-sg` | `--security-group`: Incorporate an IP into a specific security group:
    ```bash
    config_ip -sg jump-server
    config_ip -sg jump-server -p bahmni
    config_ip -sg jump-server -p bahmni -r
    ```
6. `-n` | `--name`: Include a distinct name through the command-line interface (CLI):
    ```bash
    config_ip -n test_user
    config_ip -sg jump-server -n test_user
    config_ip -sg jump-server -p bahmni -n test_user
    ```