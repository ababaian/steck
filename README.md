# Steck
Project Logan assembly analysis toolkit
Adapted from https://gitlab.pasteur.fr/rchikhi_pasteur/logan-analysis/

### Warning / Costs
Running this system costs real $'s in your AWS bill. Spot instances with local disk are 0.0022$ per vCPU-hour (https://instances.vantage.sh/aws/ec2/c5d.4xlarge). E.g. a 10,000 vCPU workload during 10 hours is 220$ total. Do a test run and use AWS Cost Explorer 24 hours later to see real costs.

### Initialize `Steck`

1. `1_deploy_container.sh push` : Build the container defined in `env/Dockerfile`, importing reference sequence sets from `ref/`. Deploy the the `Steck` ECR.

2. `2_form_cloud.sh` : Build the `Steck-batch` cloud environment using CloudFormation YAML.

### Running `Steck`

1. `run_steck.sh <runs/job_parameters.list>` : Submits a job-queue for `Steck` to submit jobss.


### Notes: 

Where dest_bucket is the name of the destination bucket, and nb_jobs is the number of jobs to submit (can't exceed 10000). The more jobs, the faster it will be. Each job takes 1 vcpu and 1.5G memory. Destination bucket file structure is decided by the task.

Tests
- `env/1_deploy_contiainer.sh test` : Run a local unit test of the `steck-container`
- `env/0_run-test.sh` : Run a test of Batch jobs

### Clean-up
Manually delete the CloudFormation stack. Also delete the ECR image.