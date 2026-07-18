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
