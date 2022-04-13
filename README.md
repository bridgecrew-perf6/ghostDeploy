# PoC: Deploy GHost on AWS

This repository offer a [Terraform](https://www.terraform.io/) module to deploy a publishing platform/app [Ghost](https://ghost.org/docs/).

## Overview

This repo can be used to host a bare bones blogging platform using [Ghost](https://ghost.org/docs/) which is run on [AWS](https://aws.amazon.com/de/ec2/) and configured using Terraform.

The repository will enable you to perform the following tasks:

- Launch an EC2 instance on AWS.
- Installs Ghost application + dependencies.
- Only allow SSH access to the instance and Gbost traffic(22 and 2368).
- Sets up a cronjob that:
  - Bumps the Ghost database(mysql)
  - Save the snapshot of the site under `/backup` directory.
  - mails you a daily summary (Mailing server not configured YET!)
- Describes a way to push changes to Ghost themes for developers.
  - Those changes can be continously deployed.
    - Ghost Theme: https://github.com/muawiakh/liebling


## :rotating_light: Things this repo is NOT :rotating_light:

- Reliable way to deploy in Production or hosting a blogging platform.


### Pre-requisites

 - Access to internet :alien:
 - Valid AWS Account, [Free tier](https://aws.amazon.com/free/) works :green_heart:
 - [Terraform](https://www.terraform.io/downloads)
   - This was developed with: Terraform v1.1.8

### Usage

- You can validate your AWS account to Terraform using the following:
  - aws-profile configured via [AWS Command Line Interface](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html)
    - I am using `muawiakh-dev` in `terraform.tfvars` file. You can edit that or comment it out and you will be prompted to add that.
  - OR 
  - Export your AWS credentials.
    - export AWS_SECRET_ACCESS_KEY="SECRET ACCESS KEY"
    - export AWS_ACCESS_KEY_ID="ACCESS KEY ID"

- Optional: If you want to have access to the instance and have all the permissions, you can specify the keypair.
  - Uncomment the `resource` section in `keypair.tf`
  - Update the `instance-key-name` in `terraform.tfvars` to the respective name.
  - This might save you the trouble of creating a new Keypair and associating it to the instance [EC2 connect](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-connect-methods.html)

- Navigate to the project directory and deploy.
```bash
cd ghostDeploy/
terraform init
terraform apply
# to avoid the prompt
# terraform apply -auto-approve
# Optional: To destroy the setup
# terraform destroy -auto-appove
```
 
 After a successfull run Terraform should output the following:
 - instance-id: _EC2 instance ID_
 - instance-public-dns: _Publicly Resolvable Domain Name for the instance_
 - instance-public-ip: _Public IP of the instance_

After the `cloud-init` script executes successfully(might take a few minutes), you can access the Ghost application at:


```bash
curl <Public IP of instance>:2368
```

Access in Browser: `http://<PUBLIC IP of instance>:2368`

**Note**: `2368` is the default port foor Ghost.
Protocol, in this case `http` is important.


### For Theme Developers

Since this is not a production deployment, we might have to do some adhoc operations. 

We are going to use an open source Ghost theme repository to demonstrate how a CI/CD workflow via Github actions can look like.

- [Liebling Theme](https://liebling.eduardogomez.io/)
  - Github: https://github.com/eddiesigner/liebling
    - [Opensource License](https://github.com/eddiesigner/liebling/blob/master/LICENSE)


You can either fork it or use the fork I created: https://github.com/muawiakh/liebling

Once the Ghost app is deployed and you have registered/started your blog:
```bash
# On the browser
http://<PUBLIC IP of instance>:2368>/ghost/

# Example data for blog creating
# Site Name: MyBlog
# Full Name: Alice Bob
# Email: alicebob@alicebob.com
# Password: abcd1234567890
```

Navigate: `Explore Ghost Admin` -> `Settings(Gear Icon)` -> `Integrations` -> `Click "Add custom itegration"` -> `Write in pop up: "Github Actions"` 

The above mentioned workflow will take you to a screen with the following content:

- Admin API key: _Admin API Access Key_
- API URL: _URL of the blog_

Both are needed in our Github Repo to use the CI/Github Actions. Head over to the Github Repo: https://github.com/muawiakh/liebling

Navigate: `Repo Homepage` -> `Settings(Gear Icon)` -> `Secrets` -> `Actions(in secrets dropdown)`

Edit/Update the pre-existing `GHOST_ADMIN_API_KEY` and `GHOST_ADMIN_API_URL` with the ones that are valid for you.

To Validate the CI workflow: 

Navigate: `Repo Homepage` -> `Actions`  -> `(Under All Workflows) Ghost Theme CI`

Once this is set up, any push events on the repository on `master` and `main` branch will trigger the pipeline(FREE) and deploy the required changes which can be verified back at the Ghost URL.


### Improvements

Obviously, this process can be improved and I will try to divide the improvements into two sections:

- Infrastructure
- Application

#### Improvements: Infrastructure

The improvements regarding infrastructure can be divided into the following sections:

  - Workflow
  - Code Quality
  - Security
  - Scale

##### Workflow

Workflow can be improved in the following ways:

- This repo can have a CI for itself, so that infrastructure changes and the terraform modules/manifests are not run locally and instead on a CI runner, which allows for better visibility/rollbacks and maintenance of infra.
- Terraform state is stored locally, which will be problematic if a multiple people are using the same resources.
  
###### Code Quality

- Terraform code could be modularized e.g. vpc creation, security groups, internet gateway can be separate manifests allowing for more flexibility.
- Keypair access can be improved by setting up `EC2 Instance Connect`


##### Security

- If the Terraform hosts are running on a remote secure location/CI runner, the secrets will be harder to compromise.
- Bastion hosts can be set up to control access to the instances or `EC2 Instance Connect`.
- Loadbalancer and WAF to prevent from attacks.

#### Scale

- Currently we are using FreeTier account, if we need to scale that has to be invested in.
- The Database(mysql) is run on the server the application is running on, which is not safe, secure or scalable, we can use a hosted/managed storage e.g. RDS or manage that ourselves.
- Terraform state can be stored remotely e.g. s3 bucket.
- Autoscaling of the hosts running the application.
- Loadbalancer to control/monitor traffic.
- WAF for more granular access to the service.
- CDN in place if we really go global. Fingers crossed.
  - Also for media uploads.
  - Content based routing.
- Monitoring/Alerting systems to view the state of the systems and take action if something goes wrong.


#### Improvements: Application

The improvements regarding the application(Ghost) can be divided into the following sections:

  - Deployment/Config Management
  - Security
  - Scale
  
##### Deployment/Config Management

- Currently the application is installed using `cloud-init`, which works for a proof-of-concept but this can be drastically improved by using a config management tool e.g. `ansible`, `salt`.
  - This will help with upgrades, config changes, host roles.
- The current deployment install the DB and the application on the same host, which should be separate concerns.
- Application is brought up using bare bones configuration, which could also be improved.

##### Security

- Application should be hosted using HTTPS.
- Admin and Application should be separate domains with separate access controls.
- Firewall and Loadbalancers, mentioned for infrastructure already.
- Access control for the database

##### Scale

- Autoscaling or Run on an orchestration system that allows easy horizontal scaling.
- Database choice and replication. 
- Backups should be uploaded.
- Better monitoring/alerting of the events/requests/logs of the application.
- Deployed in multiple zones/dcs.
- Caching layers for READ operations since a blog might have more read than write operations.
