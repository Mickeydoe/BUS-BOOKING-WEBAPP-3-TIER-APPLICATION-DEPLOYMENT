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


=======================================================================

                                      Internet
                                          │
                                          │
                                  ┌─────────────────┐
                                  │ Internet Gateway│
                                  └─────────────────┘
                                          │
            ───────────────────────── Public Subnet ─────────────────────────
                                          │
                                          │
                            ┌──────────────────────────┐
                            │  Public ALB (Internet)   │
                            └──────────────────────────┘
                                          │
                        ┌─────────────────┴─────────────────┐
                        │                                   │
                        ▼                                   ▼
              ┌────────────────┐                 ┌────────────────┐
              │ Frontend EC2 #1 │               │ Frontend EC2 #2 │
              │  Nginx + Static │               │  Nginx + Static │
              └────────────────┘               └────────────────┘
                        ▲                                   ▲
                        └────────── Frontend ASG ───────────┘
                                          │
                                          │
                                   HTTP /api/*
                                          │
                                          ▼
                         ┌────────────────────────────┐
                         │ Internal Application ALB   │
                         └────────────────────────────┘

            ─────────────────────── Private App Subnets ─────────────────────
                                          │
                        ┌─────────────────┴─────────────────┐
                        │                                   │
                        ▼                                   ▼
              ┌────────────────┐                 ┌────────────────┐
              │ Backend EC2 #1 │               │ Backend EC2 #2 │
              │ Flask/Gunicorn │               │ Flask/Gunicorn │
              └────────────────┘               └────────────────┘
                        ▲                                   ▲
                        └────────── Backend ASG ────────────┘
                                          │
                                   PostgreSQL (5432)
                                          │
                                          ▼

            ─────────────────────── Private DB Subnets ──────────────────────

                              ┌────────────────────────┐
                              │ Amazon RDS PostgreSQL  │
                              └────────────────────────┘


Outbound Internet Access
──────────────────────────────────────────────────────────────────────────────

Frontend EC2
        │
        ▼
Internet (public subnet)

Backend EC2
        │
        ▼
┌───────────────┐
│ NAT Gateway A │────────────┐
└───────────────┘            │
                             │
┌───────────────┐            │
│ NAT Gateway B │────────────┘
└───────────────┘
        │
        ▼
Internet Gateway


Request flow

User accesses the application via the Public ALB.
The Public ALB routes requests to the Frontend Auto Scaling Group.
Nginx serves the static HTML, CSS, and JavaScript.
JavaScript makes requests such as GET /api/pass-types or POST /api/book.
Nginx forwards /api/* requests to the Internal ALB.
The Internal ALB distributes requests across the Backend Auto Scaling Group.
Flask handles the request and communicates with Amazon RDS PostgreSQL.
The response flows back through the Internal ALB → Frontend → Public ALB → User.