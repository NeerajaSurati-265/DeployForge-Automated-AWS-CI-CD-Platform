from fastapi import FastAPI, status
from pydantic import BaseModel, Field

from app import APP_NAME, __version__


class RootResponse(BaseModel):
    name: str = Field(..., description="Application name")
    version: str = Field(..., description="Application version")
    message: str = Field(..., description="Short welcome message")


class HealthResponse(BaseModel):
    status: str = Field(..., description="Service health status indicator")


class VersionResponse(BaseModel):
    version: str = Field(..., description="Current application version")


app = FastAPI(
    title=APP_NAME,
    version=__version__,
    description="Production-style REST API for Automated AWS Deployment Platform",
)


@app.get(
    "/",
    response_model=RootResponse,
    status_code=status.HTTP_200_OK,
    summary="Application root details",
)
def get_root() -> RootResponse:
    """Return application name, version, and a welcome message."""
    return RootResponse(
        name=APP_NAME,
        version=__version__,
        message="Welcome to the Automated AWS Deployment Platform API.",
    )


@app.get(
    "/health",
    response_model=HealthResponse,
    status_code=status.HTTP_200_OK,
    summary="Health check endpoint",
)
def get_health() -> HealthResponse:
    """Return health status of the application."""
    return HealthResponse(status="healthy")


@app.get(
    "/version",
    response_model=VersionResponse,
    status_code=status.HTTP_200_OK,
    summary="Application version endpoint",
)
def get_version() -> VersionResponse:
    """Return the current application version."""
    return VersionResponse(version=__version__)
