# Flask CI/CD with Jenkins, Docker, AWS ECR, and EC2

## Overview

This project demonstrates a simple CI/CD pipeline that automatically builds and deploys a Flask application using Jenkins and Docker on AWS.

The pipeline performs the following steps:

1. Pulls the latest source code from GitHub
2. Builds a Docker image for the Flask application
3. Pushes the image to Amazon ECR
4. Connects to an EC2 application server
5. Pulls the new image and restarts the container

The result is an automated deployment workflow triggered by GitHub commits.

---

## Architecture

Developer → GitHub → Jenkins → Amazon ECR → App EC2 → Running Container

Components used:

- **GitHub** – Source code repository
- **Jenkins** – CI/CD automation server
- **Docker** – Containerization
- **Amazon ECR** – Container image registry
- **EC2 (Jenkins Server)** – Builds and pushes images
- **EC2 (Application Server)** – Runs the Flask container
- **Terraform** – Infrastructure provisioning

---

## Repository Structure
    .
    ├── app.py 
    ├── Dockerfile 
    ├── requirements.txt 
    ├── Jenkinsfile 
    ├── compose.yaml 
    └── terraform/

---


---

## Jenkins Pipeline Stages

The pipeline performs the following stages:

1. **Build Docker Image**
2. **Tag Image for ECR**
3. **Authenticate to AWS ECR**
4. **Push Image to ECR**
5. **Deploy to Application EC2**

Deployment is executed via SSH from the Jenkins server to the application EC2 instance.

---

## Application Access

After deployment, the Flask application runs inside a Docker container on the application EC2.

Example:
    
    http://APP_EC2_PUBLIC_IP:5000

---


---

## Infrastructure

Infrastructure is provisioned using Terraform and includes:

- Jenkins EC2 instance
- Application EC2 instance
- IAM roles
- Security groups
- ECR repository
- SSH key pairs

---

## CI/CD Flow

1. Code is pushed to GitHub
2. GitHub triggers Jenkins via webhook
3. Jenkins builds the Docker image
4. Jenkins pushes the image to ECR
5. Jenkins connects to the application EC2
6. The application server pulls the new image and redeploys the container

---

## Notes

- Jenkins uses an IAM role to authenticate to ECR
- SSH key-based authentication is used for deployment
- Containers are recreated on each deployment