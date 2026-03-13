# Terraform Guide

## 1. The Terraform Life-Cycle CLI Commands

| Command               | Short Description                                            | Industrial Use Case                                               |
|-----------------------|--------------------------------------------------------------|-------------------------------------------------------------------|
| `terraform init`      | Initializes the working directory and downloads plugins.      | Always run after adding new modules or backend configurations.   |
| `terraform validate`  | Checks if configuration is syntactically valid.              | Use in pre-commit hooks to catch errors before planning.          |
| `terraform plan`      | Generates an execution plan showing changes.                 | Mandatory for code reviews to prevent accidental destruction.     |
| `terraform apply`     | Executes the actions proposed in a plan.                     | Use `-auto-approve` only in automated non-production environments.|
| `terraform refresh`   | Updates the state file with real-world status.               | Used to detect "drift" (manual changes made in the AWS Console).  |

<br>

## 2 Terraform Workspace

* Terraform workspaces allow you to manage multiple instances of the same infrastructure configuration
* They provide isolated state files so that resources in one workspace do not interfere with resources in another
* By default, Terraform has a `default` workspace
* Creating additional workspaces is useful for managing environments like `dev`, `staging`, and `prod`

| Command                           | Short Description                                             |
|-----------------------------------|---------------------------------------------------------------|
| `terraform workspace list`        | Show all available workspace including default                |
| `terraform workspace show`        | Show the current workspace the user is working on             |
| `terraform workspace new dev`     | creates a new workspace and switches to it                    | 
| `terraform workspace select dev`  | switches to the selected workspace for isolation of others    |
| `terraform workspace delete dev`  | DeLetes the workspace and its .tfstate files as well          |

<br>

## 3. Terraform Commands with Workspace Selection

* When using workspaces, simply switching the workspace isn't enough if you have environment-specific values (like different instance sizes or VPC CIDRs)
* ou must combine the workspace context with variable files (`.tfvars`)
* `.tfvars` files are "Environment Identity"
* Using `-var-file` tells Terraform to swap out values (like IP addresses or instance sizes) depending on which file it reads
* `.tfvars` acts as a "Hard Link" between your code and the actual cloud



| Command                                                  | Industrial Use Case                                                                 |
| :------------------------------------------------------- | :---------------------------------------------------------------------------------- |
| `terraform workspace show`                               | Displays the current active workspace (e.g., `default`, `dev`, or `prod`)           |
|                                                          | *Industrial:* Mandatory first step before any destructive or deployment action.     |
| `terraform workspace select <name>`                      | Switches the context to a specific environment (eg: `select dev`)                   |
|                                                          | *Industrial:* Ensures the CLI is "pointed" at the correct backend state.            |
| `terraform plan -var-file="dev.tfvars"`                  | Previews changes specifically for the dev environment.                              |
|                                                          | *Industrial:* Ensures you aren't accidentally hitting production resources.         |
| `terraform apply -var-file="dev.tfvars" -auto-approve`   | Deploys the configuration using dev variables.                                      | 
|                                                          | *Industrial:* Used after a plan has been reviewed and approved in a Pull Request.   |
| `terraform destroy -var-file="prod.tfvars"`              | Completely removes the infrastructure associated with the prod workspace.           |
|                                                          | *Industrial:* **Warning:** Always verify your workspace before running this.        |


<br>

## 4. Professional File Structure
Organizing code into specialized files is the "Gold Standard" for maintainability.

* **`providers.tf`**: Defines the AWS/GCP/Azure provider, version constraints, and backend (S3/DynamoDB) for state locking
* **`variables.tf`**: The "Input API" where you declare variable names, types (string, list, map), and descriptions
* **`terraform.tfvars`**: The actual data file where you provide values for your `variables.tf` file
    * `terraform.tfvars` ― (default workspace)
    * `dev.tfvars` ― with smaller vlaues (instance_type = "t3.medium")
    * `test.tfvars` ― with slightly larger values (instance_type = "t4.large")
    * `prod.tfvars` ― with real life big values (instance_type = "t5.extralarge")
* **`main.tf`**: The primary entry point where you call modules or define core resources
* **`security.tf`**: Dedicated file for Security Groups, IAM roles, and NACLs
* **`outputs.tf`**: The "Return Values" that print important IDs or IPs to your terminal
* **`modules/`**: Sub-directories containing reusable blocks of code for VPC, Compute, or Databases

<br>

## 5. Terraform System "Keywords" (The Language Anatomy)

Terraform uses specific Reserved Keywords to identify what type of logic you are implementing.  
These are the "`System Variables`" of the HCL language.

| System Variables  | Type        | Short Description                                                                                | Usage                                        |
|-------------------|-------------|------------------------------------------------------------------------------------------------- |----------------------------------------------|
| `variable`        | Inputs      | The "Questions" your code asks, to make code resusable                                           | `variable "instance_type" { type = string }` |
| `resource`        | Creators    | The "Actions." This tells Terraform to physically create something in the cloud                  | `resource "aws_instance" "web" { ... }` |
| `data`            | Readers     | The "Queries." This looks up information that already exists in AWS without trying to create it. | `data "aws_ami" "ubuntu" { ... }` |
| `output`          | Returns     | The "Answers." This prints information to your screen after the code runs                        | `output "public_ip" { value = aws_instance.web.public_ip }` |
| `module`          | Containers  | The "Packages." This calls a collection of resources from another folde                          | `module "my_vpc" { source = "./modules/vpc" }` |
| `locals`          | Calculators | Internal variables used to simplify complex math or strings within a single file                 | `locals { full_name = "${var.project}-${var.env}" }` |

<br>

## 6. The Evolution of HCL Templates

### Level 1: Hardcoded (Beginner)

Simple but rigid. Every change requires editing the resource block directly

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16" # Hardcoded value
}
```

### Level 2: Scalable Lists & Count (Intermediate)

Uses `count` and `length()` to create multiple resources from a single block, given with multiple varaibles/.tfvars file values (eg using list)

```hcl
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs) # Dynamic count
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index] # Index-based selection
  availability_zone = element(var.availability_zones, count.index) # Wraps around list
}
```

### Level 3: The for_each Loop (Advanced)

Preferred over count because it uses "Keys" instead of "Indexes," making resource management safer

```hcl
resource "aws_iam_role_policy_attachment" "iam_role_attach" {
  for_each   = toset(var.iam_policy_arns) # Converts list to unique set
  role       = aws_iam_role.ssm_role.name
  policy_arn = each.value # Refers to the current item in the loop
}
```

* `toset()` / `tolist()`: Used to clean up data before passing it into a `for_each` loop

### Level 4: Dynamic Blocks (Expert)

Allows you to create nested blocks (like Security Group rules) dynamically based on a variable values provided (varaibles.tf or .tfvars file)

```hcl
resource "aws_security_group" "public_sg" {
  name = "dynamic-sg"
  
  dynamic "ingress" {
    for_each = var.public_sg_rules # Looping through a list of objects
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }
}
```

* `dynamic` blocks: The cleanest way to handle repeating configurations like multiple ports in a Security Group

<br>

## 7. Essential AWS Resource Names

As a Cloud Engineer, these are the "Must-Know" resources you will use in almost every VPC architecture (AWS):

* `aws_vpc`: The virtual network boundary
* `aws_internet_gateway`: Connects the VPC to the internet
* `aws_subnet`: Segments the VPC into public and private areas
* `aws_nat_gateway`: Allows private instances to reach the internet safely
* `aws_route_table`: The "GPS" of the VPC, directing traffic flows
* `aws_route`: A specific entry within a route table that directs traffic to a gateway, peering connection, or NAT
* `aws_security_group`: The instance-level stateful firewall
* `aws_instance`: The virtual server (EC2)
* `aws_db_instance`: Managed relational databases (RDS)

*Advance*
* `aws_iam_policy`: A document that defines permissions (e.g., "Allow Read on S3"). This is the "What" in security
* `aws_iam_role_policy_attachment`: The "Glue" that binds an IAM Policy to a specific IAM Role
* `aws_vpc_peering_connection`: Connects two VPCs so they can communicate using private IP addresses as if they were on the same network
* `aws_db_subnet_group`: A collection of subnets (usually private) that you designate for your RDS database instances
* `aws_lb`: An Application or Network Load Balancer that distributes incoming traffic across multiple EC2 targets
* `aws_s3_bucket`: Scalable object storage for files, static websites, or Terraform state files
* `aws_kms_key`: Key Management Service for encrypting data at rest, such as EBS volumes or RDS databases

<br>

## 8. The Terraform Code Phases

### **Phase 1**: Meta-Arguments (The Orchestrators)

These are "`system-level`" arguments used inside a resource or module block to define how that resource is provisioned

| Keyword          | Purpose                                                                                                                 |
|------------------|-------------------------------------------------------------------------------------------------------------------------|
| `count`          | Creates a fixed number of resources based on a number or a list's length                                                |
| `for_each`       | Creates multiple resources based on a Map or Set of strings. This is the industry standard for identity-based resources |
| `depends_on`     | Explicitly defines a hidden dependency (e.g., ensure an IAM role is ready before the EC2 uses it)                       |
| `lifecycle`      | Controls resource behavior (e.g., `prevent_destroy`, `ignore_changes`, or `create_before_destroy`)                      |

<br>

### Phase 2: Collection & Data Cleaning Functions

In industry, data often arrives "messy." These functions prepare your lists and maps to be "`loop-ready`"

1. **Sorting & Preparation**:
   * `toset(list)`: Removes duplicates and converts a list to a set. Mandatory for `for_each`
   * `tolist(set)`: Converts a set back to a list to maintain order
   * `tomap(object)`: Explicitly casts an object into a key-value map

2. **Cleaning & Filtering**:
   * `flatten(list(list))`: Merges nested lists into one flat list
   * `compact(list)`: Removes all "null" or empty strings from a list
   * `distinct(list)`: Returns a new list with all duplicate elements removed

3. **Safe Selection**:
   * `lookup(map, key, default)`: Fetches a value from a map. If the key is missing, it uses a default value to prevent code crashes
   * `element(list, index)`: Picks an item from a list. If the index exceeds length, it "wraps around" back to index 0

<br>

### Phase 3: Operators & Logic (The Decision Makers)

These allow your code to think. As a Cloud Engineer, one should use these to make one codebase work for multiple environments

* Conditional Operators
  - **Ternary (`? :`)**: `condition ? true_val : false_val`. Used for toggling features (e.g., instance_count = var.env == "prod" ? 3 : 1)
* Mathematical Operators:
  - **Arithmetic**: `+`, `-`, `*`, `/`, `%` (modulo)
  - **Comparison**: `==`, `!=`, `>`, `<`, `>=`, `<=`
* Transformation Operators:
  - **for expressions**: Iterates over a list/map to create a new list/map (e.g., `[for s in var.subnets : upper(s)]`)
  - **Splat (`[*]`)**: Extracts a specific attribute from all items in a list (e.g., `aws_instance.web[*].public_ip`)


<br>

### Phase 4: Dynamic & Content Blocks (The Nested Loops)

This is for resources that require "`sub-blocks`" like *Security Group ingress rules* or *Auto Scaling Group tags*

* **`dynamic "block_name"`**: Declares the start of a repeating inner block
* **`for_each (Inside Dynamic)`**: The list or map that provides the data for the repeating block
* **`content {}`**: The actual body of the repeating block where you map the data to the resource's attributes

<br>

### Phase 5: System & String Functions

Used for reading files, formatting strings, and preparing cloud-native configurations

* **File & Templates:**
  - `file(path)`: Reads a local file's content (e.g., your SSH `.pub` key)
  - `templatefile(path, vars)`: Injects Terraform variables into a Bash or Python script before sending it to EC2
* **Encoding & Formatting:**
  - `jsonencode(object)`: Converts HCL maps/lists into a JSON string. Mandatory for IAM policies
  - `join(separator, list)`: Combines a list into one string (e.g., "`10.0.1.0/24`, `10.0.2.0/24`")
  - `lower() / upper()`: Normalizes string case for naming consistency

<br>

### Summary Table

| Stage        | Focus Area      | Key Tools to Master                                           |
|--------------|-----------------|---------------------------------------------------------------|
| 1. Inputs    | Data Gathering  | `variable`, `data`, `file()`, `jsonencode()`                  |
| 2. Cleaning  | Type Safety     | `toset()`, `flatten()`, `lookup()`, `element()`               |
| 3. Logic     | Decision Making | `condition ? true : false`, `for` expressions                 |
| 4. Loops     | Provisioning    | `for_each`, `count`, `dynamic`, `depends_on`                  |
| 5. Safety    | Export & Protect| `lifecycle`, `outputs`, Splat `[*]`, Remote State             |

<br>

## 9. Industrial Professionalism: Best Practices

* **`State Locking`**: Always use an S3 backend with DynamoDB to prevent two people from running apply at the same time
* **`Variables Over-Defaulting`**: Avoid hardcoding values in main.tf. Pass everything through variables.tf to keep your modules "Clean" and "Generic"
* **`Module Versioning`**: In large teams, reference specific versions of modules (e.g., ?ref=v1.2.0) so that new changes don't break existing infrastructure
* **`Least Privilege`**: Only attach the specific IAM policies needed (like AmazonSSMManagedInstanceCore) rather than AdministratorAccess

<br>

## 10. Load Testing & Performance Validation

Testing ensures that your Auto Scaling Group (ASG) policies actually trigger when the application is under pressure.

### 1. Internal Stress (CPU-Bound Utilization Testing)

* **Tool**: Linux Utility: `stress`
* **Target**: EC2 Instance `CPU` and `RAM`
* **Mechanism**: Runs high-intensity mathematical calculations directly on the server to spike CPU usage
* **Use Case**: Validating `ASG` Target Tracking Policies based on `AverageCPUUtilization`
  ```bash
  # Stresses 2 CPU cores for 300 seconds
   stress --cpu 2 --timeout 300s
  ```
  ```bash
  # Stresses 4 CPU cores for 300 seconds
  # when instance type has t3.micro (2 CPUs), then having 4 will put 100% stress for 2 CPUs
   stress --cpu 4 --timeout 300s
  ```
   
### 2. External Stress (I/O & Request-Bound Testing)

* **Tool**: `k6` (Modern) or `ApacheBench` (Legacy)
* **Target**: Application Load Balancer (`ALB`) and Network Throughput
* **Mechanism**: Simulates hundreds or thousands of concurrent users hitting the API endpoint from outside the network
* **Use Case**: Validating ALB `RequestCountPerTarget` policies and testing the "breaking point" of the web server (Kestrel/IIS/Nginx)

#### 2.1. using k6 for request testing
* k6 is an open-source load-testing tool developed by Grafana Labs
* Unlike older tools that use XML or custom GUIs, k6 uses JavaScript to write tests
* This allows you to treat your performance tests exactly like your application code (Load-Testing-as-Code)
* It uses a "Go" engine under the hood, meaning one single local machine can simulate thousands of virtual users (VUs) without breaking a sweat

* What else can k6 do?
  - **CPU Stressing**: If your API does heavy work (like image processing, PDF generation, or complex math), k6 will naturally drive up the EC2 CPU usage as it forces the server to process those requests
  - **Soak Testing**: You can run k6 for hours at a medium load to find "Memory Leaks." If your API memory usage keeps climbing but never goes down, you have a leak
  - **Spike Testing**: You can configure k6 to go from 0 to 1,000 users in 5 seconds. This tests if your Load Balancer can handle a sudden "viral" moment without dropping connections
  - **Breakpoint Testing**: You slowly increase users until the server finally crashes. This tells you the exact "breaking point" of a t3.micro

* Use Cases:
  - **CI/CD Integration**: You can put k6 in your GitHub Actions. If a new code change makes the API 50% slower, k6 can automatically "fail" the build
  - **Scalability Testing**: Exactly what you just did—verifying that AWS Auto Scaling actually "wakes up" when traffic hits
  - **Reliability Testing**: Checking if the system returns `500 Errors` when the database gets overwhelmed
 
  ```bash
  # administrative mode
  choco install k6 -y
  ```
  ```bash
  # Simulates 200 concurrent users for 5 minutes
  k6 run --vus 200 --duration 5m stress-test.js
  ```
  ```bash
  k6 run stress-test.js
  ```
  ```bash
  # stress-test.js
  # result VUS requests - approx 52,00,000 within 5 minutes
  # .net core web api hosted on private ec2, handled by ALB, survived this 52 lakh request within 5 minutes without crashing
  
   import http from 'k6/http';
   import { sleep } from 'k6';
   
   export const options = {
     vus: 200,          // 200 virtual users (concurrency)
     duration: '5m',    // Run for 5 minutes to trigger the ASG
   };
   
   export default function () {
     http.get('https://api.millstack.in/weatherforecast');
     sleep(0.1); // Small sleep to prevent your local PC from crashing
   }
  ```

#### 2.2. Apache Bench (`ab`)

* Apache Bench is a single-threaded command-line utility used for benchmarking and load testing HTTP web servers
* Originally designed for the Apache HTTP Server, it is generic enough to test any web server (Nginx, .NET Kestrel, etc.)

Core Use Cases
- **Baseline Benchmarking**: Quickly finding the maximum "Requests per Second" (RPS) a single server can handle
- **Connection Overhead Testing**: Comparing results with and without the -k flag to see how much time is wasted on TCP handshakes
- **Warm-up Tests**: Running a quick burst of traffic to ensure JIT (Just-In-Time) compilers or caches are "warmed up" before more complex testing

Critical Limitations (Why we moved to k6)
- **Single-Threaded**: `ab` uses only one OS thread. On high-capacity servers, `ab` itself can become the bottleneck before the server does
- **No Protocol Support**: It is strictly for HTTP/HTTPS. It cannot test WebSockets, gRPC, or complex database-heavy flows
- **No Scripting**: You cannot "follow" a user journey (e.g., Login -> Add to Cart -> Checkout). It only hits one URL repeatedly
- **No Redirect Support**: As we saw earlier, `ab` does not automatically follow 301/302 redirects, which can skew results in modern HTTPS-forced environments

Commands:
   ```bash
   # administrative mode
   choco install apache-httpd -y
   ```
   ```bash
   # inside the ab.exe installation folder
   ab -n 500000 -c 200 https://api.millstack.in/weatherforecast
   ```

| **Flag**       | **Name**           | **Short Description**                                                                              |
| :------------- | :----------------- | :------------------------------------------------------------------------------------------------- |
| `-n`           | **Number**         | Total number of requests to perform for the benchmarking session                                   |
| `-c`           | **Concurrency**    | Number of multiple requests to perform at a time (simultaneous users)                              |
| `-k`           | **KeepAlive**      | Enables HTTP KeepAlive, allowing multiple requests in one session (simulates modern browsers)      |
| `-t`           | **Timelimit**      | Maximum seconds to spend on benchmarking (overrides `-n`)                                          |
| `-H`           | **Header**         | Appends extra headers (e.g., `-H` "`Authorization: Bearer token`")                                 |
