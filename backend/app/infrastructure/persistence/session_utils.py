"""
session_utils — Background task helpers for DB session management
=================================================================
Provides spawn_with_own_session() to safely run fire-and-forget coroutines
that need DB access without reusing (and potentially outliving) the caller's
request-scoped session.

Pattern this replaces:
    asyncio.ensure_future(some_coro(db, ...))  # ← db may be closed/expired

Correct pattern:
    spawn_with_own_session(some_coro, arg1, arg2, task_name="my_task")
"""

import asyncio
from collections.abc import Callable, Coroutine
from typing import Any

import structlog

logger = structlog.get_logger()


def spawn_with_own_session(
    coro_factory: Callable[..., Coroutine[Any, Any, Any]],
    /,
    *args: Any,
    task_name: str = "background_task",
    **kwargs: Any,
) -> None:
    """
    Schedule *coro_factory(db, *args, **kwargs)* as a fire-and-forget asyncio
    task with a freshly-created AsyncSession.

    The session is opened inside the wrapper, so it is guaranteed to be alive
    for the entire duration of the coroutine — regardless of when the calling
    request context is torn down.

    Args:
        coro_factory: Async callable whose first positional argument is an
                      AsyncSession.  Example: ``_notify_checkpoint``
        *args:        Positional arguments forwarded after the session.
        task_name:    Label used in error logs to identify the task.
        **kwargs:     Keyword arguments forwarded to *coro_factory*.
    """
    from app.infrastructure.persistence.database import AsyncSessionLocal

    async def _wrapper() -> None:
        try:
            async with AsyncSessionLocal() as db:
                await coro_factory(db, *args, **kwargs)
        except Exception as exc:
            logger.error(
                f"{task_name}_failed",
                error=str(exc),
                exc_info=True,
            )

    asyncio.ensure_future(_wrapper())
