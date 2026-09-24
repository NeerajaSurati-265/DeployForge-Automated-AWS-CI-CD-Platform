# Automated AWS Deployment Platform

A production-style cloud deployment platform demonstrating an end-to-end containerized DevOps workflow for AWS.

## Project Overview

The **Automated AWS Deployment Platform** is designed to demonstrate modern cloud and DevOps engineering practices: building a modular microservice, packaging it with Docker, provisioning cloud infrastructure via Infrastructure as Code (IaC), and automating testing and deployment with CI/CD pipelines.

## Current Phase

**Phase 1: Application Scaffold & Containerization**

In this initial phase, the core Python REST API has been built with FastAPI and packaged into an optimized, secure Docker container running as a non-root user.

## Technology Stack

- **Language:** Python 3.11
- **Framework:** FastAPI
- **ASGI Server:** Uvicorn
- **Data Validation & Schemas:** Pydantic
- **Testing:** Pytest & FastAPI TestClient (HTTPX)
- **Containerization:** Docker (Linux Alpine/Slim base image, non-root security)

## Project Structure

```text
.
├── app/
│   ├── __init__.py        # Package initialization and version definition
│   └── main.py            # FastAPI application and endpoint definitions
├── tests/
│   ├── __init__.py        # Test package marker
│   └── test_main.py       # Pytest unit and integration test suite
├── Dockerfile             # Multi-stage/lean production Docker image definition
├── requirements.txt       # Pinned application and test dependencies
├── .dockerignore          # Docker build exclusion rules
├── .gitignore             # Git version control ignore rules
└── README.md              # Project documentation
```

## Local Setup

### Prerequisites

- Python 3.10+ (Python 3.11 recommended)
- `pip` and `virtualenv`

### Installation

1. Create and activate a Python virtual environment:

   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   ```

2. Install dependencies:

   ```bash
   pip install -r requirements.txt
   ```

3. Run the development server locally:

   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

4. Access the API documentation at `http://localhost:8000/docs`.

## Running Tests

Execute the automated test suite using `pytest`:

```bash
pytest
```

To run with verbose output:

```bash
pytest -v
```

## Docker Build & Run

### 1. Build the Docker Image

```bash
docker build -t automated-aws-deployment-platform .
```

### 2. Run the Docker Container

```bash
docker run -p 8000:8000 automated-aws-deployment-platform
```

The application will be accessible at `http://localhost:8000`.

## API Endpoints

| Method | Endpoint   | Description                                           | Sample Response                                                                                         |
| :----- | :--------- | :---------------------------------------------------- | :------------------------------------------------------------------------------------------------------ |
| `GET`  | `/`        | Returns application name, version, and welcome message | `{"name": "Automated AWS Deployment Platform", "version": "0.1.0", "message": "Welcome to the..."}`     |
| `GET`  | `/health`  | Health check endpoint for ALB and ECS orchestrators   | `{"status": "healthy"}`                                                                                 |
| `GET`  | `/version` | Returns the current application release version       | `{"version": "0.1.0"}`                                                                                  |

## Planned CI/CD Architecture

Subsequent phases of this project will introduce full automated cloud delivery:

- **GitHub Actions:** CI/CD pipeline to automatically execute tests, perform linting, and build Docker images on push or pull requests.
- **Amazon ECR (Elastic Container Registry):** Secure container registry to store version-tagged application images.
- **Terraform:** Infrastructure as Code (IaC) to provision and manage AWS resources (VPC, subnets, Application Load Balancers, Security Groups, and ECS services).
- **Amazon ECS (Elastic Container Service):** Serverless container execution using AWS Fargate for scalability, high availability, and isolation.
- **Automated Deployment:** Zero-downtime rolling deployments triggered automatically whenever changes are merged into the main branch.
