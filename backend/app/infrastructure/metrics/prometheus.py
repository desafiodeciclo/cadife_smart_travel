"""
Prometheus Metrics Configuration
Sets up Prometheus instrumentation for FastAPI.
"""
from prometheus_fastapi_instrumentator import Instrumentator
from fastapi import FastAPI

def setup_metrics(app: FastAPI):
    """Configure and expose Prometheus metrics endpoint."""
    instrumentator = Instrumentator(
        should_group_status_codes=True,
        should_instrument_requests_inprogress=True,
        excluded_handlers=["/health", "/docs", "/redoc", "/openapi.json"],
    )
    instrumentator.instrument(app).expose(app, endpoint="/metrics", include_in_schema=False)
