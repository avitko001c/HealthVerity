## Overview and Thoughts

  - Since the exercise was only to deploy a single django app I opted to use *AWS Elastic Container Service* and have 
    everything contained in its own application naming standard. *ECS* is cheaper then *EKS* and *EKS* wouldn't make 
    sense for a single app if costs were an issue.
  - I designed this *XAAS* using *AWS Elastic Container Service* instead of *Elastic Beanstalk* because *ECS*
    provides granular security control by launching containers in your own *Amazon VPC*, allowing the use of *VPC 
    security groups* and network *ACLs*. Using *IAM*, you can determine which services and resources a container 
    is allowed to access. ECS allows you to take advantage of *AWS* services such as *Elastic Load Balancing*, 
    *Elastic Container Registry*, *AWS Batch*, and *CloudWatch* via native integration with those services.
    Whereas *Elastic Beanstalk* is more of a *One Stop Shop* that takes care of everything for you but you lose
    that granular security control. It's more for someone who is new to *AWS* and just needs it hosted and running.
  - For the purposes of this exercise I developed terraform to create and depoly everything all at once using some
    `local-exec` statements after the *ECR* is created. Using this in a *Development/Staging/Production* environment 
    for continued use is not the preferred way.
  - I would setup a CI/CD pipeline to create the docker images and push them to the registry when a developer 
    creates a pull request. You could use a managed *CI/CD* service like *CircleCI* or *AWs CodePipeline. A local 
    software to perform *CI/CD* functions like *Jenkins/Travis* or whatever flavor of pipeline software your 
    company uses. With the included scripts to automate the build/push process they can easily be incorporated 
    into a pipeline with a *JenkinsFile/.circleci/create-pipeline.json* in the repo. 
  - If this was one of many applications that were to be hosted then I would create a *AWS EKS cluster* and write 
    the terraform code to deploy to the *Development/Staging/Prduction* cluster using the hashicorp kubernetes 
    provider. Containers can then be managed with the kubectl command tool and container services can be more 
    customized to fit your company needs. Networking and Security can be even tighter with *EKS* and you have more
    control over your environment.
  - The `terraform apply` outputs an *ALB URL* which needs to be manually added as a *CNAME* record for the allowed
    hosts variable domain. You can use *Route53* to host your domain and use `terraform` to add that record after
    the alb is created. This removes another manual step.

## Some Gotchya's

  - Since this terraform code is creating the ECR's for the first time there may be errors with the `update-ecr.py` 
    `local-exec` commands. It may be required to authenticate docker with the new repositories before being able to 
    push to them. 
  - I am using a local remote state for `terraform` and there is a weird bug with version 0.12 on up where a destroy 
    fails with `Error:- Failed to load state: Terraform 0.14.3 does not support state version 4, please update` if
    this happens I did not find a good workaround. I prefer using a remote state like consul/dynamodb/s3 or even
    terraform cloud.
  - I was only able to deploy this using localstack and there are some things localstack cannot complete like an ALB 
    or a complete ECR repository. If you want to deploy this in your *Development/Staging/Production* environment 
    please update the `provider.tf`, `backend.tf`. `variables.tf`,  and `data.tf` with your specifics.
  

## How to use ths project

1. Install Terraform and awscli

2. Install *AWS* account keys for awscli and Terraform

3. Update the variables in `terraform/calibrate/variables.tf` and update the `provider.tf`, `data.tf`, and `backend.tf` 
   files for your account. The file `provider.example` is provided as an example.

4. Set the following environment variables, init Terraform, create the infrastructure:

    ```sh
    $ cd terraform
    $ export AWS_ACCESS_KEY_ID="YOUR_AWS_ACCESS_KEY_ID"
    $ export AWS_SECRET_ACCESS_KEY="YOUR_AWS_SECRET_ACCESS_KEY"

    $ terraform init
    $ terraform apply
    $ cd ..
    ```
   What running `terraform apply` will create...
    - RDS
        - Updates the `calibrate_app/Dockerfile` with 
          the rds endpoint
    - ECR:
        - Calibrate_App Repository
          - Create DOCKER image
          - Push DOCKER image
        - Nginx Repository
          - Create DOCKER image
          - Push DOCKER image
    - ECS:
        - Task Definition (with multiple containers)
        - Cluster
        - Service
        - Launch Config
        - Key Pairs
    - LoadBalanceing
        - Calibrate ALB
        - Calibrate Listener
        - Calibrate Target Group
          - Health Check
    - AutoScaling
        - ECS AutoScaling Group
    - IAM Roles and Policies
        - Host Role and Policy
        - ECS Service Role and Policy
        - ECS Instance Profile
    - Networking:
        - VPC
        - Public and Private subnets
        - Routing Tables
        - Internet Gateway
    - Security:
        - ALB Security Group
        - ECS Security Group
        - RDS Security Group
    - CloudWatch
        - Calibrate Log Group and Stream
        - Nginx Log Group and Stream

5. Terraform will output an *ALB domain URL*. Create a *CNAME* record in the DNS domain 
   of the `allowed_hosts` variable.

6. If you want to log into the container and check the application goto AWS console
   open the EC2 instances overview page in AWS. Use `ssh ec2-user@<ip>` to connect 
   to the instances until you find one for which `docker ps` contains the Django 
   container.

   `docker exec -it <ContainerID>`

7. Now you can open `https://your.domain.com/admin`. Note that `http://` won't work.

8. Manually Build the Calibrate and Nginx Docker images and push them up to ECR:

    ```sh
    $ cd calibrate
    $ docker build -t <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/calibrate-app:latest .
    $ docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/calibrate-app:latest
    $ cd ..

    $ cd nginx
    $ docker build -t <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/nginx:latest .
    $ docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/nginx:latest
    $ cd ..
    ```

9. You can also run the following script to bump the ECS Task Definition and update the Service:

    ```sh
    $ cd deploy
    $ python update-ecs.py --cluster=production-cluster --service=production-service
    ```
