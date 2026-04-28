"""
LeadStateMachine — Application Layer
=====================================
Explicit state-transition rules for the Lead lifecycle (spec.md §8.4).
Enforces valid transitions at the application level before any DB write.

Valid transitions:
  NOVO → EM_ATENDIMENTO
  EM_ATENDIMENTO → QUALIFICADO
  QUALIFICADO → AGENDADO | PROPOSTA
  AGENDADO → PROPOSTA
  PROPOSTA → FECHADO
  Any state → PERDIDO

PERDIDO is a terminal state — no outbound transitions.
"""
from __future__ import annotations

from app.domain.entities.enums import LeadStatus


class InvalidStateTransitionError(ValueError):
    """Raised when a lead status transition violates the lifecycle rules."""

    def __init__(self, current: LeadStatus, target: LeadStatus, message: str | None = None) -> None:
        self.current = current
        self.target = target
        default_msg = (
            f"Transição de estado inválida: '{current.value}' → '{target.value}'. "
            f"Transições permitidas a partir de '{current.value}': "
            f"{[s.value for s in LeadStateMachine.get_allowed_transitions(current)]}."
        )
        super().__init__(message or default_msg)


class LeadStateMachine:
    """
    Finite-state machine for Lead lifecycle.
    Pure business rules — no framework or DB dependencies.
    """

    # Mapping: current_status -> set of allowed next statuses
    _transitions: dict[LeadStatus, set[LeadStatus]] = {
        LeadStatus.novo: {LeadStatus.em_atendimento, LeadStatus.perdido},
        LeadStatus.em_atendimento: {LeadStatus.qualificado, LeadStatus.perdido},
        LeadStatus.qualificado: {LeadStatus.agendado, LeadStatus.proposta, LeadStatus.perdido},
        LeadStatus.agendado: {LeadStatus.proposta, LeadStatus.perdido},
        LeadStatus.proposta: {LeadStatus.fechado, LeadStatus.perdido},
        LeadStatus.fechado: {LeadStatus.perdido},
        LeadStatus.perdido: set(),  # terminal state
    }

    @classmethod
    def can_transition(cls, current: LeadStatus, target: LeadStatus) -> bool:
        """Return True if the transition is allowed."""
        allowed = cls._transitions.get(current, set())
        return target in allowed

    @classmethod
    def validate_transition(cls, current: LeadStatus, target: LeadStatus) -> None:
        """
        Validate a transition.

        Raises:
            InvalidStateTransitionError: If the transition is not allowed.
        """
        if not cls.can_transition(current, target):
            raise InvalidStateTransitionError(current, target)

    @classmethod
    def get_allowed_transitions(cls, current: LeadStatus) -> list[LeadStatus]:
        """Return a list of valid next states for the given current state."""
        return sorted(
            cls._transitions.get(current, set()),
            key=lambda s: list(LeadStatus).index(s),
        )
