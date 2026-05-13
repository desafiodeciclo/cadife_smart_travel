# Re-export the canonical Offer model for Alembic and infrastructure imports.
# The domain model lives in app.models.offer — this file was a legacy duplicate
# with pt-BR column names that conflicted with the active ORM mapping.
from app.models.offer import Offer as OfferModel  # noqa: F401
