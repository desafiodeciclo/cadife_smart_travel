"""
Tests — Application/Services/LeadStateMachine
==============================================
Unit tests for the Lead lifecycle finite-state machine.
Pure business rules — no database or framework dependencies.

Coverage targets:
  - All valid transitions (spec.md §8.4)
  - All invalid transitions return False / raise
  - PERDIDO is reachable from every non-terminal state
  - Terminal state (PERDIDO) has no outbound transitions
"""
import pytest

from app.application.services.lead_state_machine import InvalidStateTransitionError, LeadStateMachine
from app.domain.entities.enums import LeadStatus


class TestLeadStateMachineValidTransitions:
    """Happy-path transitions defined in spec.md §8.4."""

    @pytest.mark.parametrize("current,target", [
        (LeadStatus.novo, LeadStatus.em_atendimento),
        (LeadStatus.em_atendimento, LeadStatus.qualificado),
        (LeadStatus.qualificado, LeadStatus.agendado),
        (LeadStatus.qualificado, LeadStatus.proposta),
        (LeadStatus.agendado, LeadStatus.proposta),
        (LeadStatus.proposta, LeadStatus.fechado),
        # PERDIDO from every state
        (LeadStatus.novo, LeadStatus.perdido),
        (LeadStatus.em_atendimento, LeadStatus.perdido),
        (LeadStatus.qualificado, LeadStatus.perdido),
        (LeadStatus.agendado, LeadStatus.perdido),
        (LeadStatus.proposta, LeadStatus.perdido),
        (LeadStatus.fechado, LeadStatus.perdido),
    ])
    def test_can_transition_returns_true(self, current: LeadStatus, target: LeadStatus) -> None:
        assert LeadStateMachine.can_transition(current, target) is True

    @pytest.mark.parametrize("current,target", [
        (LeadStatus.novo, LeadStatus.em_atendimento),
        (LeadStatus.qualificado, LeadStatus.proposta),
    ])
    def test_validate_transition_does_not_raise(self, current: LeadStatus, target: LeadStatus) -> None:
        LeadStateMachine.validate_transition(current, target)  # should not raise


class TestLeadStateMachineInvalidTransitions:
    """Transitions that violate the lifecycle rules must be rejected."""

    @pytest.mark.parametrize("current,target", [
        # Backwards
        (LeadStatus.em_atendimento, LeadStatus.novo),
        (LeadStatus.qualificado, LeadStatus.em_atendimento),
        (LeadStatus.agendado, LeadStatus.qualificado),
        (LeadStatus.proposta, LeadStatus.agendado),
        (LeadStatus.fechado, LeadStatus.proposta),
        # Skips
        (LeadStatus.novo, LeadStatus.qualificado),
        (LeadStatus.em_atendimento, LeadStatus.agendado),
        (LeadStatus.novo, LeadStatus.fechado),
        # Terminal state outbound
        (LeadStatus.perdido, LeadStatus.novo),
        (LeadStatus.perdido, LeadStatus.em_atendimento),
        (LeadStatus.perdido, LeadStatus.fechado),
        # Self-loop (not defined as valid)
        (LeadStatus.novo, LeadStatus.novo),
        (LeadStatus.qualificado, LeadStatus.qualificado),
    ])
    def test_can_transition_returns_false(self, current: LeadStatus, target: LeadStatus) -> None:
        assert LeadStateMachine.can_transition(current, target) is False

    @pytest.mark.parametrize("current,target", [
        (LeadStatus.fechado, LeadStatus.novo),
        (LeadStatus.perdido, LeadStatus.qualificado),
        (LeadStatus.novo, LeadStatus.proposta),
    ])
    def test_validate_transition_raises(self, current: LeadStatus, target: LeadStatus) -> None:
        with pytest.raises(InvalidStateTransitionError) as exc_info:
            LeadStateMachine.validate_transition(current, target)
        assert current.value in str(exc_info.value)
        assert target.value in str(exc_info.value)


class TestLeadStateMachineHelpers:
    """Auxiliary methods on the state machine."""

    def test_get_allowed_transitions_novo(self) -> None:
        allowed = LeadStateMachine.get_allowed_transitions(LeadStatus.novo)
        assert allowed == [LeadStatus.em_atendimento, LeadStatus.perdido]

    def test_get_allowed_transitions_qualificado(self) -> None:
        allowed = LeadStateMachine.get_allowed_transitions(LeadStatus.qualificado)
        assert allowed == [LeadStatus.agendado, LeadStatus.proposta, LeadStatus.perdido]

    def test_get_allowed_transitions_perdido_is_empty(self) -> None:
        allowed = LeadStateMachine.get_allowed_transitions(LeadStatus.perdido)
        assert allowed == []

    def test_error_contains_current_and_target(self) -> None:
        exc = InvalidStateTransitionError(LeadStatus.proposta, LeadStatus.novo)
        assert exc.current == LeadStatus.proposta
        assert exc.target == LeadStatus.novo
        assert "proposta" in str(exc)
        assert "novo" in str(exc)
