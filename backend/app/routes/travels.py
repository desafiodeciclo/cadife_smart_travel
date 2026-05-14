import uuid

from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional

from app.infrastructure.adapters.storage.s3_adapter import S3StorageAdapter
from app.infrastructure.security.dependencies import get_current_user, get_db
from app.infrastructure.persistence.models.user_model import UserModel
from app.infrastructure.persistence.models.travel_model import TravelModel
from app.infrastructure.persistence.repositories.documento_repository import DocumentoRepository
from app.presentation.schemas.document_schema import DocumentResponse, DocumentsListResponse, DocumentType
from app.presentation.schemas.travel_schema import TravelResponse, TravelListResponse, TravelStatus

router = APIRouter(prefix="/travels", tags=["travels"])


@router.get("", response_model=TravelListResponse)
async def list_travels(
    status: Optional[TravelStatus] = Query(None, description="Filter by status"),
    db: AsyncSession = Depends(get_db),
    current_user: UserModel = Depends(get_current_user),
):
    """
    List travels for authenticated user.

    Ordenação: por start_date (próximas primeiro).
    Filtro: por status (upcoming, ongoing, completed).
    """
    query = select(TravelModel).where(
        TravelModel.user_id == current_user.id
    )

    if status:
        query = query.where(TravelModel.status == status.value)

    query = query.order_by(TravelModel.start_date.asc())

    result = await db.execute(query)
    travels = result.scalars().all()

    travels_response = [
        TravelResponse(
            id=str(travel.id),
            user_id=str(travel.user_id),
            destination=travel.destination,
            start_date=travel.start_date,
            end_date=travel.end_date,
            status=travel.status,
            image_url=travel.image_url,
            description=travel.description,
        )
        for travel in travels
    ]

    return TravelListResponse(
        travels=travels_response,
        count=len(travels_response),
    )


@router.get("/{travel_id}", response_model=TravelResponse)
async def get_travel(
    travel_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: UserModel = Depends(get_current_user),
):
    """
    Get specific travel by ID.
    """
    try:
        tid = uuid.UUID(travel_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid travel ID format")

    result = await db.execute(
        select(TravelModel).where(
            TravelModel.id == tid,
            TravelModel.user_id == current_user.id,
        )
    )
    travel = result.scalar_one_or_none()

    if not travel:
        raise HTTPException(status_code=404, detail="Travel not found")

    return TravelResponse(
        id=str(travel.id),
        user_id=str(travel.user_id),
        destination=travel.destination,
        start_date=travel.start_date,
        end_date=travel.end_date,
        status=travel.status,
        image_url=travel.image_url,
        description=travel.description,
    )


@router.get("/{travel_id}/documents", response_model=DocumentsListResponse)
async def get_travel_documents(
    travel_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: UserModel = Depends(get_current_user),
):
    """
    Get documents for a specific travel.
    """
    try:
        tid = uuid.UUID(travel_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid travel ID format")

    # Validate that travel belongs to user
    result = await db.execute(
        select(TravelModel).where(
            TravelModel.id == tid,
            TravelModel.user_id == current_user.id,
        )
    )
    travel = result.scalar_one_or_none()
    if not travel:
        raise HTTPException(status_code=404, detail="Travel not found")

    # Get documents
    repo = DocumentoRepository(db)
    documents = await repo.list_by_travel(tid)

    # Generate presigned URLs
    storage = S3StorageAdapter()

    # Convert to schema
    docs_response = []
    for doc in documents:
        url = await storage.generate_presigned_url(doc.s3_key)
        doc_type = DocumentType.OTHER
        if doc.mimetype == "application/pdf":
            doc_type = DocumentType.PDF
        elif doc.mimetype.startswith("image/"):
            doc_type = DocumentType.IMAGE

        docs_response.append(
            DocumentResponse(
                id=str(doc.id),
                travel_id=str(doc.travel_id) if doc.travel_id else travel_id,
                name=doc.nome,
                type=doc_type,
                size_kb=doc.tamanho_bytes // 1024,
                url=url or doc.s3_key,
                uploaded_at=doc.criado_em,
            )
        )

    return DocumentsListResponse(
        documents=docs_response,
        count=len(docs_response),
    )
