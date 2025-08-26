# Cloud Resume Challenge (CRC) – AWS Edition

Welcome! This repository showcases my completion of the [Cloud Resume Challenge](https://cloudresumechallenge.dev/) using AWS services and infrastructure-as-code (IaC) with Terraform.

## Project Overview

This project demonstrates how I built and deployed a secure, scalable static website using:
this is currently running and examples of tf files can be seen in this repository. 
- **AWS S3** for hosting static files
- **CloudFront** for global CDN + HTTPS
- **Route 53** for domain management
- **Certificate Manager** for SSL/TLS
- **API Gateway + Lambda** for dynamic visitor counter
- **DynamoDB** to store the visitor count
- **Terraform** to manage infrastructure as code
- **GitHub + GitHub Actions** for CI/CD deployment

Live site: [https://hagedorny.dev/CRC/index.html](https://hagedorny.dev/CRC/index.html)

##  Infrastructure Breakdown

| Component         | Technology         |
|------------------|--------------------|
| Frontend Hosting | S3 + CloudFront    |
| HTTPS/SSL        | AWS ACM            |
| Custom Domain    | Route 53           |
| Visitor Counter  | API Gateway + Lambda + DynamoDB |
| Infra Management | Terraform          |
| CI/CD            | GitHub Actions     |

## Security Features
- HTTPS via CloudFront & ACM
- CORS and bucket policies for restricted access
- Terraform state stored securely (not included in repo)
- Principle of least privilege for IAM roles
