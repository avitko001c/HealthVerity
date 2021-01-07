## Overview and Thoughts

  *For the purposes of this exercise I developed terraform to create and depoly everything
  All at once using some local-exec statements after the ECR is created. Using this in a
  Development/Staging/Production environment for continued use is not the preferred way.
  I would setup a CI/CD pipeline to create the docker images and push them to the registry 
  when a developer creates a pull request. You could use something to perform CI/CD functions
  like Jenkins/CircleCI/AWS CodePipeline or whatever flavor of pipeline software your company 
  uses. With the included scripts to automate the build/push process they can easily be 
  incorporated into a pipeline with a JenkinsFile/.circleci in the repo. I was only able to 
  deploy this using localstack and there are some things localstack cannot complete like an 
  ALB or a complete ECR repository. Since the exercise was only to deploy a single django
  app I opted to use AWS Elastic Container Service and have everything contained in its own
  application naming standard. ECS is cheaper then EKS and wouldn't make sense for a single
  app.  If this was one of many applications that were to be hosted I would create a AWS EKS 
  cluster and write the terraform code to deploy to the Development/Staging/Prduction cluster 
  using the hashicorp kubernetes provider. Containers can then be managed with the kubectl 
  command tool and container services can be more customized to fit your company needs*.

## Some Gotchya's

  - Since this terraform code is creating the ECR's for the first time there may be errors
    with the update-ecr.py local-exec commands. It may be required to authenticate docker
    with the new repositories before being able to push to them. 
  - I am using a local remote state for *terraform* and there is a weird bug with version
    0.12 on up where a destroy fails with the error... 

    ```diff
    *-Error:- Failed to load state: Terraform 0.14.3 does not support state version 4, please update*
    ```  
  

## How to use ths project

1. Install Terraform and awscli

2. Install AWS account keys for awscli and Terraform

3. Update the variables in *terraform/variables.tf* and update the provider.tf file for your account
   provider.example is used as an example.

4. Set the following environment variables, init Terraform, create the infrastructure:

    ```sh
    $ cd terraform
    $ export AWS_ACCESS_KEY_ID="YOUR_AWS_ACCESS_KEY_ID"
    $ export AWS_SECRET_ACCESS_KEY="YOUR_AWS_SECRET_ACCESS_KEY"

    $ terraform init
    $ terraform apply
    $ cd ..
    ```
   What running *terraform apply* will create...
    - ECR:
        - Create DOCKER image
        - Push DOCKER image
    - ECS:
        - Task Definition (with multiple containers)
        - Cluster
        - Service
        - Launch Config and Auto Scaling Group
        - Security Groups
        - Load Balancers, Listeners, and Target Groups
    - IAM Roles and Policies
    - Networking:
        - VPC
        - Public and Private subnets
        - Routing Tables
        - Internet Gateway
        - Key Pairs
    - RDS
    - Health Checks and Logs

5. Terraform will output an ALB domain. Create a CNAME record for this domain
   for the value in the `allowed_hosts` variable.

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