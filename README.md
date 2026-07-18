# Simple AWS Three-Tier Pass Booking System

I built this project to get a practical understanding of how a basic three-tier application works on AWS. I wanted to keep the first version simple, so I focused on the main services that make up the architecture instead of adding too many services at once.

The application allows a customer to complete a pass-booking form. The request is handled by a Python Flask application running on EC2, and the booking is stored in an Amazon RDS PostgreSQL database.

## Architecture

![Simple AWS three-tier pass booking architecture](docs/architecture-diagram.png)

The application follows this request flow:

```text
Customer browser
        |
        | HTTP port 80
        v
Application Load Balancer
        |
        | HTTP port 5000
        v
EC2 Auto Scaling Group
Flask + HTML + CSS
        |
        | PostgreSQL port 5432
        v
Private Amazon RDS PostgreSQL
```

The Application Load Balancer and EC2 application instances are placed across two public subnets. RDS is placed inside two private database subnets.

The EC2 instances have public IP addresses because they need internet access during startup to install the required Python packages. However, the Flask application is not open directly to the internet. The EC2 security group allows port `5000` only from the ALB security group.

RDS is not publicly accessible. Its security group allows PostgreSQL connections on port `5432` only from the EC2 application security group.

## AWS services used

The main services used in this project are:

- **Amazon VPC** for the project network.
- **Amazon EC2** for running the Flask application.
- **Application Load Balancer** for receiving and distributing customer requests.
- **EC2 Auto Scaling** for maintaining and replacing application instances.
- **Amazon RDS for PostgreSQL** for storing the booking records.

Terraform also creates the supporting resources required by the architecture:

- Two public subnets across two Availability Zones.
- Two private database subnets across two Availability Zones.
- An Internet Gateway and route tables.
- Security groups for the ALB, EC2 instances and RDS.
- An EC2 launch template.
- An ALB target group and listener.
- An RDS DB subnet group.

## Frontend

I designed the frontend as a modern travel and pass-booking website using HTML and CSS.

It includes:

- A responsive landing page.
- A CSS-based ticket illustration.
- A customer booking form.
- A booking-confirmation page.
- A page for viewing records stored in RDS.
- A mobile-responsive layout.

The HTML and CSS are served by Flask from the EC2 application instances. There is no separate frontend hosting service in this version.

## Backend

The backend is written in Python using Flask.

The Flask application is responsible for:

1. Receiving the booking form.
2. Validating the submitted information.
3. Creating a unique booking reference.
4. Inserting the booking into PostgreSQL.
5. Committing the database transaction.
6. Displaying a confirmation page.

The customer submits:

```text
Full name
Email address
Phone number
Pass type
Travel date
```

SQLAlchemy is used to communicate with the database.

The main routes are:

```text
GET  /
Displays the booking form.

POST /book
Validates and stores a booking.

GET  /success/<reference>
Displays the booking confirmation.

GET  /bookings
Displays the records stored in the database.

GET  /health
Used by the Application Load Balancer health check.
```

## Auto Scaling and load balancing

The EC2 instances are launched from a Terraform-managed launch template.

The Auto Scaling Group is configured with:

```text
Minimum capacity: 1
Desired capacity: 2
Maximum capacity: 3
```

The ALB checks each EC2 instance through:

```text
/health
```

When an instance returns HTTP `200`, the ALB marks it as healthy and can send customer requests to it.

When an EC2 instance is terminated or becomes unhealthy, the Auto Scaling Group can launch a replacement. The booking data is not lost because the records are stored in RDS rather than on the EC2 instance.

## Project structure

```text
simple-aws-three-tier-booking/
├── app/
│   ├── app.py
│   ├── requirements.txt
│   ├── static/
│   │   ├── style.css
│   │   └── style.min.css
│   └── templates/
│       ├── base.html
│       ├── index.html
│       ├── success.html
│       └── bookings.html
│
├── terraform/
│   ├── alb.tf
│   ├── compute.tf
│   ├── data.tf
│   ├── network.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── rds.tf
│   ├── security.tf
│   ├── terraform.tfvars.example
│   ├── user_data.sh.tftpl
│   ├── variables.tf
│   └── versions.tf
│
├── docs/
│   ├── architecture-diagram.png
│   ├── architecture-diagram.svg
│   ├── 502_TROUBLESHOOTING.md
│   ├── STEP_BY_STEP_GUIDE.md
│   └── USER_DATA_SIZE.txt
│
└── README.md
```

## Running the project locally

The application uses SQLite during local development, so PostgreSQL does not need to be installed on my computer.

Move into the application folder:

```bash
cd app
```

Create a Python virtual environment:

```bash
python -m venv venv
```

Activate the environment on Linux or macOS:

```bash
source venv/bin/activate
```

Activate it on Windows PowerShell:

```powershell
.\venv\Scripts\Activate.ps1
```

Install the required packages:

```bash
pip install -r requirements.txt
```

Start the Flask application:

```bash
python app.py
```

Open the website at:

```text
http://localhost:5000
```

The local SQLite database is created automatically under:

```text
app/instance/bookings.db
```

## Deploying to AWS

The AWS infrastructure is created with Terraform.

Move into the Terraform folder:

```bash
cd terraform
```

Create the variables file.

Linux or macOS:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Windows PowerShell:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

Initialize Terraform:

```bash
terraform init
```

Format and validate the configuration:

```bash
terraform fmt -recursive
terraform validate
```

Create and review the execution plan:

```bash
terraform plan -out=booking.tfplan
terraform show booking.tfplan
```

Apply the plan:

```bash
terraform apply booking.tfplan
```

After deployment, display the ALB website address:

```bash
terraform output website_url
```

The complete deployment process is explained in:

```text
docs/STEP_BY_STEP_GUIDE.md
```

## How I confirm that the database is working

After submitting a dummy booking, I can open:

```text
http://ALB-DNS-NAME/bookings
```

When the booking appears, it confirms that:

```text
The browser reached the Application Load Balancer.
The ALB routed the request to EC2.
Flask processed the submitted form.
The EC2 application connected to RDS.
PostgreSQL stored and returned the booking.
```

I can also connect to PostgreSQL from one of the EC2 instances using the `psql` terminal client.

## Security-group flow

```text
Internet
   |
   | TCP 80
   v
ALB security group
   |
   | TCP 5000
   v
EC2 application security group
   |
   | TCP 5432
   v
RDS security group
```

The security groups reference each other instead of relying on fixed EC2 IP addresses. This is important because Auto Scaling can terminate and replace application instances.

## Current limitations

This is a learning project rather than a production-ready booking platform.

At the moment:

- The application uses HTTP instead of HTTPS.
- There is no user login or authentication.
- The `/bookings` page is publicly accessible.
- EC2 instances are in public subnets.
- The database password is included in Terraform state and EC2 user data.
- The application uses the RDS master account.

For that reason, I only use dummy customer information when testing the project.

## Improvements I plan to add later

After fully understanding this basic version, I can improve it gradually by adding:

1. Private application subnets for EC2.
2. A NAT Gateway or VPC endpoints.
3. HTTPS with ACM.
4. A custom domain with Route 53.
5. User and administrator authentication.
6. Protection for the `/bookings` page.
7. AWS Secrets Manager for database credentials.
8. CloudWatch logs and alarms.
9. A CI/CD deployment pipeline.
10. Separate development and production environments.

## Destroying the infrastructure

The project creates resources that can generate AWS charges.

When I have finished testing, I remove them with:

```bash
terraform destroy
```

The RDS database is configured without a final snapshot in this learning version, so destroying the infrastructure also deletes the stored booking records.

# Simple AWS Three-Tier Pass Booking System

A beginner-friendly project using only the core AWS services:

text
Amazon VPC
Amazon EC2
Application Load Balancer
EC2 Auto Scaling
Amazon RDS PostgreSQL



Terraform also creates the supporting networking and security resources required by those services:

text
Public and private subnets
Internet Gateway
Route tables
Security groups
Launch template
Target group
ALB listener



## Frontend design

The designed interface uses a modern travel/pass-booking style with:

text
Responsive hero section
CSS-only ticket illustration
Professional booking form
Modern confirmation page
Polished RDS records table
Mobile-responsive layout
No external image or JavaScript dependency



The application architecture and Terraform infrastructure are unchanged.

## Architecture

text
Customer browser
      |
      | HTTP
      v
Application Load Balancer
      |
      | Port 5000
      v
EC2 Auto Scaling Group
Flask + HTML + CSS
      |
      | PostgreSQL port 5432
      v
Private Amazon RDS PostgreSQL



The load balancer and application EC2 instances use two public subnets. RDS uses two private database subnets.

The EC2 instances have public IP addresses only so they can install Python packages without a NAT Gateway. Their security group does not allow direct public inbound traffic to the Flask port. Only the ALB security group can reach port 5000.

This is a deliberate beginner design. A later version can move EC2 into private application subnets and add a NAT Gateway or VPC endpoints.

## What the application does

The customer submits:

text
Full name
Email
Phone number
Pass type
Travel date



The Flask backend:

1. Receives the HTML form.
2. Validates the information.
3. Creates a booking reference.
4. Inserts a row into PostgreSQL.
5. Commits the database transaction.
6. Displays a confirmation page.

The 
/bookings page lists stored records so you can prove that RDS is receiving the data. It has no authentication, so use only dummy information.

## Run locally

bash
cd app
python -m venv venv



Activate the environment.

Linux or macOS:

bash
source venv/bin/activate



Windows PowerShell:

powershell
.\venv\Scripts\Activate.ps1



Install and start:

bash
pip install -r requirements.txt
python app.py



Open:

text
http://localhost:5000



Local development uses SQLite automatically. AWS uses PostgreSQL automatically through environment variables created by Terraform.

## Deploy to AWS

Follow:

text
docs/STEP_BY_STEP_GUIDE.md



## Important limitation

This learning version uses HTTP, has no login system, and exposes the demonstration 
/bookings page. Do not use real customer information. You have to redo this readme with a natural tone like me writing it and make sure to add the architecture diagram 

Generated image: AWS three-tier pass booking system diagram

I rewrote the README in a more natural, first-person tone and added an architecture diagram that matches the actual Terraform configuration, including the correct VPC and subnet CIDR ranges.

The diagram now correctly shows:

VPC: 10.20.0.0/16

Public Subnet 1: 10.20.0.0/24
Public Subnet 2: 10.20.1.0/24

Private DB Subnet 1: 10.20.10.0/24
Private DB Subnet 2: 10.20.11.0/24

Internet → ALB port 80
ALB → EC2 port 5000
EC2 → RDS port 5432


Library
/README.md

# Simple AWS Three-Tier Pass Booking System

This is a simple three-tier pass booking application that I built to understand how a frontend, backend and database work together on AWS.

A customer completes a booking form on the website. The Python Flask application processes the form and stores the booking in an Amazon RDS PostgreSQL database.

## Architecture

![Simple AWS Three-Tier Pass Booking Architecture](docs/architecture-diagram.png)

The request follows this path:

```text
User
  → Application Load Balancer
  → EC2 instances in an Auto Scaling Group
  → Amazon RDS PostgreSQL
```

## Technologies used

- **Frontend:** HTML and CSS
- **Backend:** Python Flask
- **Database:** Amazon RDS PostgreSQL
- **Infrastructure:** Terraform
- **AWS services:** VPC, EC2, Application Load Balancer, Auto Scaling and RDS

## Project structure

```text
simple-aws-three-tier-booking/
├── app/
│   ├── app.py
│   ├── requirements.txt
│   ├── static/
│   └── templates/
│
├── terraform/
│   ├── network.tf
│   ├── security.tf
│   ├── alb.tf
│   ├── compute.tf
│   ├── rds.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── docs/
│   └── architecture-diagram.png
│
└── README.md
```

## Run the project locally

Move into the application folder:

```bash
cd app
```

Create a Python virtual environment:

```bash
python -m venv venv
```

Activate it on Windows PowerShell:

```powershell
.\venv\Scripts\Activate.ps1
```

Activate it on Linux or macOS:

```bash
source venv/bin/activate
```

Install the required packages:

```bash
pip install -r requirements.txt
```

Start the application:

```bash
python app.py
```

Open the website in your browser:

```text
http://localhost:5000
```

The local version uses SQLite automatically.

## Deploy the project to AWS

First, make sure Terraform and the AWS CLI are installed and that your AWS credentials are configured.

Check your AWS account:

```bash
aws sts get-caller-identity
```

Move into the Terraform folder:

```bash
cd terraform
```

Create your Terraform variables file.

Windows PowerShell:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

Linux or macOS:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Initialize Terraform:

```bash
terraform init
```

Format and validate the files:

```bash
terraform fmt -recursive
terraform validate
```

Create a Terraform plan:

```bash
terraform plan -out=booking.tfplan
```

Apply the plan:

```bash
terraform apply booking.tfplan
```

After the deployment completes, display the website address:

```bash
terraform output website_url
```

Open the address in your browser.

## Test the application

1. Open the website using the ALB address.
2. Complete the booking form using dummy information.
3. Submit the form.
4. Confirm that a booking reference is displayed.
5. Open the bookings page:

```text
http://ALB-DNS-NAME/bookings
```

The submitted booking should appear on the page. This confirms that the Flask application successfully stored the data in RDS PostgreSQL.

## Check the load balancer targets

Run:

```bash
aws elbv2 describe-target-health \
  --target-group-arn "$(terraform output -raw target_group_arn)"
```

The EC2 targets should show as:

```text
healthy
```

## Remove the AWS resources

The project creates resources that may generate AWS charges.

When I finish testing, I remove the infrastructure with:

```bash
terraform destroy
```

## Important note

This is a learning project. It currently uses HTTP, does not have user authentication and exposes the `/bookings` page.

Only dummy customer information should be used.

Library
/README.md

# Simple AWS Three-Tier Pass Booking System

This is a simple three-tier pass booking application that I built to understand how a frontend, backend and database work together on AWS.

A customer completes a booking form on the website. The Python Flask application processes the form and stores the booking in an Amazon RDS PostgreSQL database.

## Architecture

![Simple AWS Three-Tier Pass Booking Architecture](docs/architecture-diagram.png)

The request follows this path:

```text
User
  → Application Load Balancer
  → EC2 instances in an Auto Scaling Group
  → Amazon RDS PostgreSQL
```

## Technologies used

- **Frontend:** HTML and CSS
- **Backend:** Python Flask
- **Database:** Amazon RDS PostgreSQL
- **Infrastructure:** Terraform
- **AWS services:** VPC, EC2, Application Load Balancer, Auto Scaling and RDS

## Project structure

```text
simple-aws-three-tier-booking/
├── app/
│   ├── app.py
│   ├── requirements.txt
│   ├── static/
│   └── templates/
│
├── terraform/
│   ├── network.tf
│   ├── security.tf
│   ├── alb.tf
│   ├── compute.tf
│   ├── rds.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── docs/
│   └── architecture-diagram.png
│
└── README.md
```

## Run the project locally

Move into the application folder:

```bash
cd app
```

Create a Python virtual environment:

```bash
python -m venv venv
```

Activate it on Windows PowerShell:

```powershell
.\venv\Scripts\Activate.ps1
```

Activate it on Linux or macOS:

```bash
source venv/bin/activate
```

Install the required packages:

```bash
pip install -r requirements.txt
```

Start the application:

```bash
python app.py
```

Open the website in your browser:

```text
http://localhost:5000
```

The local version uses SQLite automatically.

## Deploy the project to AWS

First, make sure Terraform and the AWS CLI are installed and that your AWS credentials are configured.

Check your AWS account:

```bash
aws sts get-caller-identity
```

Move into the Terraform folder:

```bash
cd terraform
```

Create your Terraform variables file.

Windows PowerShell:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

Linux or macOS:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Initialize Terraform:

```bash
terraform init
```

Format and validate the files:

```bash
terraform fmt -recursive
terraform validate
```

Create a Terraform plan:

```bash
terraform plan -out=booking.tfplan
```

Apply the plan:

```bash
terraform apply booking.tfplan
```

After the deployment completes, display the website address:

```bash
terraform output website_url
```

Open the address in your browser.

## Test the application

1. Open the website using the ALB address.
2. Complete the booking form using dummy information.
3. Submit the form.
4. Confirm that a booking reference is displayed.
5. Open the bookings page:

```text
http://ALB-DNS-NAME/bookings
```

The submitted booking should appear on the page. This confirms that the Flask application successfully stored the data in RDS PostgreSQL.

## Check the load balancer targets

Run:

```bash
aws elbv2 describe-target-health \
  --target-group-arn "$(terraform output -raw target_group_arn)"
```

The EC2 targets should show as:

```text
healthy
```

## Remove the AWS resources

The project creates resources that may generate AWS charges.

When I finish testing, I remove the infrastructure with:

```bash
terraform destroy
```

## Important note

This is a learning project. It currently uses HTTP, does not have user authentication and exposes the `/bookings` page.

Only dummy customer information should be used.

