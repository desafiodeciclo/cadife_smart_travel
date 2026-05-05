"""
Database portable types for PostgreSQL and SQLite compatibility.
"""
import uuid
from typing import Any

from sqlalchemy import JSON, String, TypeDecorator
from sqlalchemy.dialects.postgresql import ARRAY, UUID as PG_UUID


class GUID(TypeDecorator):
    impl = PG_UUID
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == "postgresql":
            return dialect.type_descriptor(PG_UUID(as_uuid=True))
        return dialect.type_descriptor(String(36))

    def process_bind_param(self, value: Any, dialect):
        if value is None:
            return None
        if dialect.name == "postgresql":
            return value
        return str(value)

    def process_result_value(self, value: Any, dialect):
        if value is None:
            return None
        return value if dialect.name == "postgresql" else uuid.UUID(value)


class StringArray(TypeDecorator):
    impl = JSON
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == "postgresql":
            return dialect.type_descriptor(ARRAY(String))
        return dialect.type_descriptor(JSON)

    def process_bind_param(self, value: Any, dialect):
        if value is None:
            return None
        return list(value)

    def process_result_value(self, value: Any, dialect):
        return value
