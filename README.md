# TechCorp AWS Infrastructure Deployment

## 📋 Project Overview

This repository contains the complete Terraform configuration for deploying TechCorp's web application infrastructure on AWS. The infrastructure is designed for high availability, security, and scalability across multiple availability zones.

### Business Context

TechCorp is launching a new web application that requires:
- High availability across multiple availability zones
- Secure network isolation with public and private subnets
- Load balancing for web traffic distribution
- Bastion host for secure administrative access
- Scalable architecture that can grow with business needs

## 🏗️ Architecture Overview

The infrastructure includes the following components:

### Network Layer
- **VPC**: Custom Virtual Private Cloud (10.0.0.0/16)
- **Subnets**: 4 subnets across 2 availability zones
  - 2 Public subnets (10.0.1.0/24, 10.0.2.0/24)
  - 2 Private subnets (10.0.3.0/24, 10.0.4.0/24)
- **Internet Gateway**: Provides internet access for public subnets
- **NAT Gateways**: 2 NAT Gateways (one per AZ) for private subnet internet access
- **Route Tables**: Properly configured routing for public and private subnets

### Security Layer
- **Web Security Group**: Controls access to web servers
  - HTTP (80) and HTTPS (443) from anywhere
  - SSH (22) from Bastion only
- **Database Security Group**: Controls access to database server
  - PostgreSQL (5432) from Web Security Group only
  - SSH (22) from Bastion only
- **Bastion Security Group**: Controls access to Bastion host
  - SSH (22) from specified IP address only

### Compute Layer
- **Bastion Host**: 1x t3.micro in public subnet with Elastic IP
- **Web Servers**: 2x t3.micro in private subnets with Apache
- **Database Server**: 1x t3.small in private subnet with PostgreSQL
- **Load Balancer**: Classic Load Balancer distributing traffic to web servers

## 📁 Repository Structure

```
terraform-assessment/
├── main.tf                        # Main Terraform configuration
├── variables.tf                   # Variable declarations
├── outputs.tf                     # Output definitions
├── terraform.tfvars              # Actual values (NOT in git)
├── terraform.tfvars.example      # Example values template
├── .gitignore                    # Git ignore rules
├── README.md                     # This file
├── user_data/
│   ├── web_server_setup.sh       # Apache installation script
│   └── db_server_setup.sh        # PostgreSQL installation script
└── evidence/
    ├── 01-terraform-plan.png         # Terraform plan output
    ├── 02-terraform-apply.png        # Terraform apply completion
    ├── 03-aws-console-instances.png  # AWS Console resources
    ├── 04-website-instance1.png      # Load balancer serving web1
    ├── 05-website-instance2.png      # Load balancer serving web2
    ├── 06-session-manager-bastion.png     # Bastion access
    ├── 07-session-manager-webserver.png   # Web server access
    └── 08-session-manager-database-postgresql.png # DB access & PostgreSQL
```

## 🚀 Prerequisites

Before deploying this infrastructure, ensure you have:

1. **AWS Account** with appropriate permissions to create:
   - VPC and networking resources
   - EC2 instances
   - Security Groups
   - Load Balancers
   - IAM roles (for Session Manager)

2. **AWS CLI** installed and configured
   ```bash
   aws configure
   ```

3. **Terraform** installed (version 1.0 or higher)
   ```bash
   terraform --version
   ```

4. **Your Public IP Address** for Bastion host SSH access
   ```bash
   curl ifconfig.me
   ```

5. **AWS Systems Manager Session Manager** (optional but recommended)
   - Provides secure access without SSH keys
   - Requires IAM role attached to instances

## 📝 Deployment Instructions

### Step 1: Clone the Repository

```bash
git clone https://github.com/YOUR-USERNAME/month-one-assessment.git
cd month-one-assessment
```

### Step 2: Configure Variables

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your values:
   ```bash
   nano terraform.tfvars
   ```

3. Update the following variables:
   - `aws_region`: Your preferred AWS region
   - `my_ip`: Your public IP address (get it from `curl ifconfig.me`)
   - `key_name`: Your EC2 key pair name (if using SSH keys)

### Step 3: Initialize Terraform

```bash
terraform init
```

This command:
- Downloads required AWS provider plugins
- Initializes the backend
- Prepares the working directory

### Step 4: Review the Execution Plan

```bash
terraform plan
```

Review the plan carefully to ensure:
- Correct number of resources will be created
- Proper naming conventions are applied
- Security group rules are as expected

### Step 5: Deploy the Infrastructure

```bash
terraform apply
```

- Type `yes` when prompted to confirm
- Deployment takes approximately 5-10 minutes
- Wait for "Apply complete!" message

### Step 6: Retrieve Important Information

```bash
terraform output
```

This displays:
- **vpc_id**: The ID of the created VPC
- **classic_lb_dns**: Load Balancer URL for accessing the website
- **bastion_public_ip**: Public IP for Bastion host access
- **web_server_private_ips**: Private IPs of web servers
- **database_private_ip**: Private IP of database server

## 🔍 Verification Steps

### 1. Verify AWS Resources

Go to AWS Console and verify:
- **VPC Dashboard**: Check VPC, subnets, route tables, IGW, NAT Gateways
- **EC2 Dashboard**: Confirm 4 instances are running
- **Load Balancers**: Verify Classic Load Balancer is active
- **Security Groups**: Check all 3 security groups exist

### 2. Test Website Access

Open your browser and navigate to the Load Balancer DNS:
```
http://[YOUR-CLB-DNS-NAME].elb.amazonaws.com
```

You should see:
- "Welcome to TechCorp!" message
- Instance ID displayed
- Refresh multiple times to see different instance IDs (load balancing)

### 3. Access Bastion Host

**Using Session Manager (Recommended):**
```bash
aws ssm start-session --target [BASTION-INSTANCE-ID]
```

**Using SSH (If configured with key pair):**
```bash
ssh -i your-key.pem ec2-user@[BASTION-PUBLIC-IP]
```

### 4. Access Web Servers from Bastion

From the Bastion host:
```bash
# SSH to web server
ssh ec2-user@[WEB-SERVER-PRIVATE-IP]

# Verify Apache is running
sudo systemctl status httpd

# Test local web page
curl http://localhost
```

### 5. Access Database Server from Bastion

From the Bastion host:
```bash
# SSH to database server
ssh ec2-user@[DATABASE-PRIVATE-IP]

# Verify PostgreSQL is running
sudo systemctl status postgresql

# Connect to PostgreSQL
sudo -u postgres psql

# Inside PostgreSQL prompt:
\l                    # List databases
\conninfo            # Show connection info
SELECT version();    # Check PostgreSQL version
\q                   # Quit
```

## 🔧 Implementation Notes & Challenges

### Challenge 1: Load Balancer Type Restriction

**Issue**: AWS new accounts have restrictions on creating Application Load Balancers (ALB).

**Solution**: Used a **Classic Load Balancer (CLB)** instead, which provides the same core functionality for this project:
- Traffic distribution across multiple web servers
- Health checks to ensure server availability
- Cross-availability zone redundancy

**Impact**: No functional difference for this use case. Both CLB and ALB distribute traffic and perform health checks.

### Challenge 2: User Data Script Execution

**Issue**: Initial deployment had issues with user data scripts not executing automatically during instance launch.

**Resolution**:
1. Manually installed Apache on web servers via AWS Systems Manager Session Manager
2. Created proper HTML files with instance metadata
3. Configured services to start on boot

**Commands used**:
```bash
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
```

### Challenge 3: IAM Role Configuration

**Issue**: After recreating instances using `terraform taint`, new instances lacked IAM instance profiles for Session Manager access.

**Resolution**:
1. Created IAM role (`EC2-SSM-Role`) with `AmazonSSMManagedInstanceCore` policy
2. Manually attached role to all EC2 instances via AWS Console
3. Verified Session Manager connectivity to all instances

**Future Improvement**: IAM roles should be added to Terraform configuration to ensure all instances are created with proper permissions automatically.

### Challenge 4: Load Balancer Instance Registration

**Issue**: Classic Load Balancer initially showed 0 registered instances after creation.

**Resolution**:
1. Manually registered web-1 and web-2 instances with the CLB
2. Waited for health checks to pass (instances moved to "InService" status)
3. Verified traffic routing through load balancer

**Root Cause**: Instance registration timing or automatic registration not configured properly in Terraform.

### Challenge 5: Database Port Configuration

**Issue**: Assignment specified MySQL port 3306, but PostgreSQL uses port 5432.

**Resolution**: Updated security group to allow port 5432 for PostgreSQL instead of 3306 for MySQL, matching the actual database being deployed.

### Lessons Learned

1. **Always verify IAM roles are attached** when creating instances that need AWS service access
2. **Test health checks and instance registration** after load balancer deployment
3. **Manual intervention may be needed** when constraints (like account limits) affect automation
4. **Session Manager is excellent** for secure access without managing SSH keys
5. **User data scripts need validation** - they may fail silently during boot
6. **Port numbers matter** - ensure security groups match actual services deployed

## 📊 Infrastructure Resources Created

Total resources created: **35+**

### Networking Resources
- 1 VPC
- 4 Subnets (2 public, 2 private)
- 1 Internet Gateway
- 2 NAT Gateways
- 2 Elastic IPs (for NAT Gateways)
- 3 Route Tables
- 6 Route Table Associations

### Security Resources
- 3 Security Groups with 15+ rules

### Compute Resources
- 4 EC2 Instances (1 bastion, 2 web, 1 database)
- 1 Elastic IP (for bastion)

### Load Balancing Resources
- 1 Classic Load Balancer
- 1 Load Balancer Listener
- Health check configurations

## 📅 Deployment Timeline

| Phase | Task | Status | Notes |
|-------|------|--------|-------|
| Phase 1 | Initial Terraform configuration | ✅ Complete | Created all .tf files |
| Phase 2 | First deployment attempt | ✅ Complete | 35 resources created |
| Phase 3 | Troubleshooting web servers | ✅ Complete | User data scripts failed |
| Phase 4 | Manual Apache installation | ✅ Complete | Via Session Manager |
| Phase 5 | IAM role configuration | ✅ Complete | Enabled Session Manager access |
| Phase 6 | Load balancer registration | ✅ Complete | Instances marked InService |
| Phase 7 | Final verification | ✅ Complete | Website accessible via CLB |
| Phase 8 | Documentation & submission | ✅ Complete | All evidence gathered |

## 🧹 Cleanup Instructions

**IMPORTANT**: To avoid ongoing AWS charges, destroy all resources after review.

### Step 1: Verify What Will Be Destroyed

```bash
terraform plan -destroy
```

### Step 2: Destroy All Resources

```bash
terraform destroy
```

- Type `yes` when prompted
- Wait for confirmation message
- Destruction takes approximately 5-10 minutes

### Step 3: Verify Cleanup

Check AWS Console to confirm:
- All EC2 instances terminated
- Load Balancer deleted
- NAT Gateways deleted
- Elastic IPs released

### Manual Cleanup (If Needed)

If some resources fail to delete automatically:

1. **Release Elastic IPs** manually from EC2 console
2. **Delete NAT Gateways** from VPC console
3. **Wait 5 minutes** for dependencies to clear
4. **Run** `terraform destroy` again

## 📊 Cost Estimation

Approximate monthly costs (us-east-1 region):

| Resource | Quantity | Estimated Cost |
|----------|----------|----------------|
| EC2 t3.micro | 3 | ~$9.00 |
| EC2 t3.small | 1 | ~$15.00 |
| NAT Gateways | 2 | ~$66.00 |
| Classic Load Balancer | 1 | ~$18.00 |
| Data Transfer | Variable | ~$10.00 |
| **Total** | | **~$118/month** |

**Note**: Destroy resources immediately after assessment to minimize costs.

## 🔐 Security Best Practices Implemented

1. **Network Isolation**: Web and database servers in private subnets
2. **Principle of Least Privilege**: Security groups restrict access to minimum required
3. **Bastion Host**: Single point of administrative access
4. **Session Manager**: Eliminates need for SSH keys in most cases
5. **No Hardcoded Credentials**: All sensitive data in terraform.tfvars (gitignored)

## 🛠️ Technologies Used

- **Terraform**: Infrastructure as Code
- **AWS VPC**: Network isolation
- **AWS EC2**: Compute resources
- **AWS Classic Load Balancer**: Traffic distribution
- **Apache HTTP Server**: Web server
- **PostgreSQL**: Database server
- **AWS Systems Manager**: Secure instance access
- **Amazon Linux 2**: Operating system

## 📚 Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/)
- [AWS EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

## 🤝 Support & Contact

For questions or issues with this deployment:

- **GitHub Issues**: [Create an issue](https://github.com/YOUR-USERNAME/month-one-assessment/issues)
- **Email**: your.email@example.com
- **Instructor**: [Instructor Name/Contact]

## 📄 License

This project is created for educational purposes as part of the TechCorp Cloud Engineering Assessment.

---

**Assignment Completion Status**: ✅ Complete

**Deployment Evidence**: All 8 required screenshots included in `evidence/` folder

**Repository**: [https://github.com/YOUR-USERNAME/month-one-assessment](https://github.com/YOUR-USERNAME/month-one-assessment)

---

*Last Updated*: November 2025  
*Created By*: Baribefe Gbara  
*Course*: Cloud Engineering Month 1 Assessment
