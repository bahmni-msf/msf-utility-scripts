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
      abcd: [
        // profile key[user wish should configure in profiles key]
        {
          sg_id: 'sg-1234', //Security group ID [from aws]
          sg_name: 'jump-server', // sg name[user wish]
          port_range: 22, // what port you want to configure [user wish]
        },
        {
          sg_id: 'sg-1234',
          sg_name: 'lb',
          port_range: 443,
        },
      ],
      bcde: [
        {
          sg_id: 'sg-1234',
          sg_name: 'jump-server',
          port_range: 22,
        },
      ],
      profiles: {
        1234: 'abcd', // account number[from aws]: key[user wish should be equal to key provided above "abcd"]
        '0123': 'bcde',
      },
      ip_file_path: '.my_ip', //to maintain state [user wish]
      name: 'msf', // to add description for ip [user wish]
    };

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