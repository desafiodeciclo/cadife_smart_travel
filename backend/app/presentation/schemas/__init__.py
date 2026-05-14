# Presentation Schemas — Pydantic schemas for API validation (request/response).
from app.presentation.schemas.leads import (
    LeadCreateRequest,
    LeadDetailDTO,
    LeadListItemDTO,
    LeadListResponseDTO,
    LeadMetricsDTO,
    LeadUpdateRequest,
)
from .lead_schema import LeadCreateSchema, LeadUpdateSchema, LeadResponseSchema
from .lead_score_history_schema import ScoreHistoryItem, ScoreHistoryResponse
from .briefing_schema import (
    BriefingExtracted,
    BriefingResponse,
    BriefingSchema,
    BriefingUpdate,
)
from .proposta_schema import (
    CancelPropostaRequest,
    PropostaCreate,
    PropostaPatchRequest,
    PropostaResponse,
    PropostaUpdate,
    PropostaVersaoDTO,
    PropostaVersoesListResponse,
)
from .password_reset_schema import (
    PasswordResetConfirm,
    PasswordResetRequest,
    PasswordResetResponse,
)
from .offer_schema import (
    OfferCreateRequest,
    OfferDetailResponse,
    OffersListResponse,
    OfferResponse,
    OfferUpdateRequest,
)
from .agendamento_schema import (
    AgendamentoCreate,
    AgendamentoListResponse,
    AgendamentoPatch,
    AgendamentoResponse,
    AgendamentoUpdate,
    CancelAgendamentoRequest,
    DisponibilidadeResponse,
    SlotDisponivel,
)
from .admin_schema import (
    AdminLeadReassignRequest,
    AdminLeadReassignResponse,
    AdminUserCreate,
    AdminUserListResponse,
    AdminUserMetrics,
    AdminUserResponse,
    AdminUserUpdate,
)
from .dead_letter_queue_schema import (
    DeadLetterQueueCreate,
    DeadLetterQueueListResponse,
    DeadLetterQueueResponse,
)
from .conversation_summary_schema import (
    ConversationSummaryListResponse,
    ConversationSummaryResponse,
    ConversationSummaryTopics,
)
from .interacao_schema import InteracaoListResponse, InteracaoResponse
from .lead_offer_schema import (
    LeadOfferCreate,
    LeadOfferListResponse,
    LeadOfferResponse,
)
from .notification_queue_schema import (
    NotificationQueueCreate,
    NotificationQueueListResponse,
    NotificationQueueResponse,
)
from .travel_checkpoint_schema import (
    TravelCheckpointCreate,
    TravelCheckpointListResponse,
    TravelCheckpointResponse,
)
from .user_schema import (
    FcmTokenRequest,
    FcmTokenResponse,
    LoginRequest,
    RefreshRequest,
    TokenResponse,
    UserProfileUpdate,
    UserResponse,
)

__all__ = [
    "LeadCreateRequest",
    "LeadUpdateRequest",
    "LeadListItemDTO",
    "LeadDetailDTO",
    "LeadListResponseDTO",
    "LeadMetricsDTO",
    "LeadCreateSchema",
    "LeadUpdateSchema",
    "LeadResponseSchema",
    "ScoreHistoryItem",
    "ScoreHistoryResponse",
    "BriefingSchema",
    "BriefingResponse",
    "BriefingUpdate",
    "BriefingExtracted",
    "PropostaCreate",
    "PropostaUpdate",
    "PropostaPatchRequest",
    "CancelPropostaRequest",
    "PropostaResponse",
    "PropostaVersaoDTO",
    "PropostaVersoesListResponse",
    "PasswordResetRequest",
    "PasswordResetConfirm",
    "PasswordResetResponse",
    "OfferCreateRequest",
    "OfferUpdateRequest",
    "OfferResponse",
    "OfferDetailResponse",
    "OffersListResponse",
    "LoginRequest",
    "TokenResponse",
    "RefreshRequest",
    "UserResponse",
    "UserProfileUpdate",
    "FcmTokenRequest",
    "FcmTokenResponse",
    "InteracaoResponse",
    "InteracaoListResponse",
    "ConversationSummaryTopics",
    "ConversationSummaryResponse",
    "ConversationSummaryListResponse",
    "AgendamentoCreate",
    "AgendamentoUpdate",
    "AgendamentoPatch",
    "CancelAgendamentoRequest",
    "AgendamentoResponse",
    "AgendamentoListResponse",
    "SlotDisponivel",
    "DisponibilidadeResponse",
    "AdminUserCreate",
    "AdminUserUpdate",
    "AdminUserMetrics",
    "AdminUserResponse",
    "AdminUserListResponse",
    "AdminLeadReassignRequest",
    "AdminLeadReassignResponse",
    "NotificationQueueCreate",
    "NotificationQueueResponse",
    "NotificationQueueListResponse",
    "DeadLetterQueueCreate",
    "DeadLetterQueueResponse",
    "DeadLetterQueueListResponse",
    "LeadOfferCreate",
    "LeadOfferResponse",
    "LeadOfferListResponse",
    "TravelCheckpointCreate",
    "TravelCheckpointResponse",
    "TravelCheckpointListResponse",
]
