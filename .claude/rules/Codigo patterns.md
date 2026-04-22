# 💻 CADIFE SMART TRAVEL — Padrões de Código & Exemplos

> **GUIA TÉCNICO COM EXEMPLOS DE IMPLEMENTAÇÃO**  
> Use como referência durante desenvolvimento

---

## 1. WEBHOOK WhatsApp (Backend)

### ✅ Padrão Correto — Responde em < 5s (Assíncrono)

```python
# backend/routes/whatsapp.py
from fastapi import APIRouter, Request, BackgroundTasks, HTTPException
from fastapi.responses import JSONResponse
from services.ai_service import process_whatsapp_message
from services.lead_service import create_or_update_lead
from models.conversation import ConversationLog
from utils.security import validate_webhook_token
import logging

router = APIRouter(prefix="/webhook")
logger = logging.getLogger(__name__)

@router.post("/whatsapp")
async def webhook_whatsapp(
    request: Request,
    background_tasks: BackgroundTasks,
):
    """
    WhatsApp Cloud API webhook endpoint.
    REGRA: Responde com HTTP 200 em < 5 segundos.
    Processamento pesado acontece em background.
    """
    
    try:
        # 1. Validar token
        verify_token = request.headers.get("X-Verify-Token")
        if not validate_webhook_token(verify_token):
            logger.warning("Invalid verify token in webhook request")
            raise HTTPException(status_code=403, detail="Forbidden")
        
        # 2. Parse payload
        payload = await request.json()
        
        # 3. Validar estrutura
        if not payload or "entry" not in payload:
            return JSONResponse({"status": "ignored"}, status_code=200)
        
        # 4. Extrair dados essenciais
        for entry in payload.get("entry", []):
            for change in entry.get("changes", []):
                if change.get("field") != "messages":
                    continue
                
                value = change.get("value", {})
                messages = value.get("messages", [])
                
                if not messages:
                    continue
                
                message = messages[0]
                sender_phone = message.get("from")
                timestamp = message.get("timestamp")
                message_id = message.get("id")
                
                # 5. Criar log de conversa IMEDIATAMENTE (fallback)
                try:
                    conv_log = ConversationLog(
                        whatsapp_message_id=message_id,
                        sender_phone=sender_phone,
                        raw_payload=payload,
                        status="received",
                        timestamp=timestamp,
                    )
                    conv_log.save()
                    logger.info(f"ConversationLog created: {conv_log.id}")
                except Exception as e:
                    logger.error(f"Failed to create ConversationLog: {e}", exc_info=True)
                
                # 6. ENVIAR PARA BACKGROUND (assíncrono)
                # ⚠️ Webhook já retornou 200, isso processa em background
                background_tasks.add_task(
                    process_whatsapp_message_async,
                    message=message,
                    payload=value,
                    message_log_id=conv_log.id if conv_log else None,
                )
        
        # ✅ Responde imediatamente (< 5s)
        return JSONResponse({"status": "ok"}, status_code=200)
    
    except Exception as e:
        logger.error(f"Webhook error: {e}", exc_info=True)
        # ⚠️ SEMPRE responder 200 para Meta, mesmo com erro
        return JSONResponse({"status": "error"}, status_code=200)


# ✅ Processamento assíncrono — roda em background
async def process_whatsapp_message_async(
    message: dict,
    payload: dict,
    message_log_id: str = None,
):
    """
    Processamento pesado em background.
    Chamado via background_tasks.add_task()
    """
    try:
        sender_phone = message.get("from")
        message_type = message.get("type")  # text, image, audio, etc
        
        logger.info(f"Processing message from {sender_phone} | Type: {message_type}")
        
        # 1. Extrair conteúdo (depende do tipo)
        content = None
        if message_type == "text":
            content = message.get("text", {}).get("body", "")
        elif message_type == "audio":
            # Transcrever áudio
            audio_data = message.get("audio", {})
            content = transcribe_audio(audio_data)
        elif message_type == "image":
            # Armazenar imagem (não processar IA ainda)
            image_data = message.get("image", {})
            store_image(image_data)
            content = "[IMAGEM RECEBIDA]"
        else:
            content = f"[TIPO NÃO SUPORTADO: {message_type}]"
        
        # 2. Chamar IA (RAG + extração)
        ai_response, briefing_extracted = await process_whatsapp_message(
            conversation_id=sender_phone,
            user_message=content,
            message_type=message_type,
        )
        
        logger.info(f"AI response generated: {len(ai_response)} chars")
        
        # 3. Validar resposta IA
        if is_response_unsafe(ai_response):
            logger.warning(f"Unsafe response detected: {ai_response[:100]}")
            ai_response = "Vou conectar você com um consultor para oferecer a melhor solução."
        
        # 4. Criar/atualizar lead
        lead = await create_or_update_lead(
            conversation_id=sender_phone,
            briefing=briefing_extracted,
            last_message_content=content,
        )
        
        logger.info(f"Lead created/updated: {lead.id} | Score: {lead.score}")
        
        # 5. Enviar resposta ao cliente
        send_whatsapp_message(
            to=sender_phone,
            message_text=ai_response,
        )
        
        # 6. Notificar agência via FCM
        notify_agency_fcm(
            lead_id=lead.id,
            notification_title="Novo Lead Recebido",
            notification_body=f"{lead.briefing.destination or 'Sem destino'} | Score: {lead.score}",
        )
        
        # 7. Atualizar status do log
        if message_log_id:
            ConversationLog.update(
                {"_id": message_log_id},
                {"status": "processed", "lead_id": str(lead.id)},
            )
        
        logger.info(f"Message processing completed for {sender_phone}")
    
    except Exception as e:
        logger.error(f"Error in async processing: {e}", exc_info=True)
        # Armazenar em failed queue para retry manual
        failed_queue.enqueue(sender_phone, payload)


def is_response_unsafe(response: str) -> bool:
    """
    Detecta respostas perigosas (preços, promessas indevidas).
    REGRA: IA NUNCA deve gerar preços ou orçamentos.
    """
    dangerous_patterns = [
        r"R\$\s*[\d.,]+",  # Detecta valores em R$
        r"USD\s*[\d.,]+",
        r"EUR\s*[\d.,]+",
        r"custa|preço|valor de",  # Palavras-chave de preço
        r"garantir|prometo|certeza que",  # Promessas indevidas
    ]
    
    for pattern in dangerous_patterns:
        if re.search(pattern, response, re.IGNORECASE):
            return True
    
    return False
```

---

## 2. AUTENTICAÇÃO JWT (Backend)

### ✅ Padrão Correto — JWT com Refresh

```python
# backend/utils/security.py
from datetime import datetime, timedelta
import jwt
from fastapi import HTTPException
from config import settings
import logging

logger = logging.getLogger(__name__)

class JWTHandler:
    @staticmethod
    def create_tokens(user_id: str, role: str) -> dict:
        """
        Cria access token (1h) e refresh token (7d).
        REGRA: Expiração configurável, tokens separados.
        """
        now = datetime.utcnow()
        
        # Access token (curta duração)
        access_payload = {
            "sub": str(user_id),
            "role": role,
            "type": "access",
            "iat": now,
            "exp": now + timedelta(hours=1),  # 1h
        }
        
        access_token = jwt.encode(
            access_payload,
            settings.JWT_SECRET_KEY,
            algorithm="HS256",
        )
        
        # Refresh token (longa duração)
        refresh_payload = {
            "sub": str(user_id),
            "type": "refresh",
            "iat": now,
            "exp": now + timedelta(days=7),  # 7d
        }
        
        refresh_token = jwt.encode(
            refresh_payload,
            settings.JWT_SECRET_KEY,
            algorithm="HS256",
        )
        
        logger.info(f"Tokens created for user {user_id}")
        
        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "expires_in": 3600,  # segundos
        }
    
    @staticmethod
    def verify_token(token: str) -> dict:
        """
        Verifica e decodifica JWT.
        Lança HTTPException se inválido.
        """
        try:
            payload = jwt.decode(
                token,
                settings.JWT_SECRET_KEY,
                algorithms=["HS256"],
            )
            
            # Verificar expiração
            if payload.get("exp") < datetime.utcnow().timestamp():
                raise HTTPException(
                    status_code=401,
                    detail="Token expired",
                )
            
            return payload
        
        except jwt.InvalidTokenError as e:
            logger.warning(f"Invalid token: {e}")
            raise HTTPException(
                status_code=401,
                detail="Invalid token",
            )
    
    @staticmethod
    def refresh_token(refresh_token: str) -> dict:
        """
        Gera novo access token a partir de refresh token.
        REGRA: Refresh token também pode ser rotacionado.
        """
        payload = JWTHandler.verify_token(refresh_token)
        
        if payload.get("type") != "refresh":
            raise HTTPException(
                status_code=401,
                detail="Invalid refresh token",
            )
        
        user_id = payload.get("sub")
        role = payload.get("role", "user")
        
        # Gerar novo par (opcional: rotacionar refresh também)
        return JWTHandler.create_tokens(user_id, role)


# ✅ Usar em endpoints
from fastapi import Depends

async def get_current_user(authorization: str = Header(...)):
    """
    Dependency para proteger endpoints.
    Extrai e valida JWT do header Authorization.
    """
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail="Invalid authorization header",
        )
    
    token = authorization[7:]  # Remove "Bearer "
    payload = JWTHandler.verify_token(token)
    
    return {
        "user_id": payload["sub"],
        "role": payload.get("role"),
    }


# ✅ Exemplo de uso
@router.post("/auth/login")
async def login(email: str, password: str):
    # Validar email/password
    user = authenticate_user(email, password)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    tokens = JWTHandler.create_tokens(user.id, user.role)
    return tokens


@router.post("/auth/refresh")
async def refresh(refresh_token: str):
    new_tokens = JWTHandler.refresh_token(refresh_token)
    return new_tokens


@router.get("/leads")
async def get_leads(current_user = Depends(get_current_user)):
    # current_user validado automaticamente
    return get_leads_for_user(current_user["user_id"])
```

---

## 3. IA + RAG (Backend)

### ✅ Padrão Correto — Chain com RAG e Extração

```python
# backend/services/ai_service.py
from langchain.chat_models import ChatOpenAI
from langchain.prompts import ChatPromptTemplate
from langchain.schema.runnable import RunnablePassthrough
from langchain.vectorstores import Chroma
from langchain.embeddings import OpenAIEmbeddings
from langchain.output_parsers import PydanticOutputParser
from pydantic import BaseModel, Field
import logging

logger = logging.getLogger(__name__)

# ✅ Schema estruturado para extração
class BriefingSchema(BaseModel):
    """Dados estruturados extraídos do briefing do cliente."""
    destination: str = Field(None, description="Destino da viagem")
    departure_date: str = Field(None, description="Data saída (YYYY-MM-DD)")
    return_date: str = Field(None, description="Data retorno (YYYY-MM-DD)")
    num_people: int = Field(None, description="Número de pessoas")
    budget_range: str = Field(None, description="Faixa de orçamento (ex: 5k-10k)")
    travel_type: str = Field(None, description="Tipo de viagem (lazer, negócio, lua-de-mel)")
    preferences: list = Field(default_factory=list, description="Preferências")
    confidence_score: float = Field(default=0, description="Confiança da extração 0-1")


class AIService:
    def __init__(self):
        self.llm = ChatOpenAI(
            model_name="gpt-4-turbo",
            temperature=0.3,  # Menos criativo, mais consistente
            max_tokens=1000,
        )
        
        # Carregar vector DB
        self.embeddings = OpenAIEmbeddings()
        self.vector_db = Chroma(
            persist_directory="./chroma_db",
            embedding_function=self.embeddings,
        )
    
    async def process_message(
        self,
        conversation_id: str,
        user_message: str,
        conversation_history: list = None,
    ) -> tuple:
        """
        Processa mensagem do usuário com RAG.
        Retorna: (resposta_texto, briefing_extraído)
        """
        logger.info(f"Processing message for {conversation_id}")
        
        try:
            # 1. Recuperar contexto da base de conhecimento (RAG)
            relevant_docs = self._retrieve_rag_context(user_message)
            rag_context = "\n".join([doc.page_content for doc in relevant_docs])
            
            # 2. Preparar chain com RAG + extração
            response_text, briefing = await self._run_rag_chain(
                conversation_id=conversation_id,
                user_message=user_message,
                rag_context=rag_context,
                history=conversation_history or [],
            )
            
            # 3. Validar resposta (não gerar preços)
            if self._contains_pricing(response_text):
                logger.warning(f"Pricing detected in response, replacing...")
                response_text = self._get_safe_fallback(response_text)
            
            # 4. Armazenar memória de conversação
            await self._store_conversation_memory(
                conversation_id=conversation_id,
                user_message=user_message,
                ai_response=response_text,
                briefing=briefing,
            )
            
            return response_text, briefing
        
        except Exception as e:
            logger.error(f"AI processing error: {e}", exc_info=True)
            return self._get_error_fallback(), None
    
    def _retrieve_rag_context(self, query: str, k: int = 3) -> list:
        """
        Recupera documentos relevantes da base de conhecimento.
        """
        try:
            results = self.vector_db.similarity_search(query, k=k)
            logger.info(f"Retrieved {len(results)} documents for query: {query[:50]}")
            return results
        except Exception as e:
            logger.error(f"RAG retrieval error: {e}")
            return []
    
    async def _run_rag_chain(
        self,
        conversation_id: str,
        user_message: str,
        rag_context: str,
        history: list,
    ) -> tuple:
        """
        Chain com RAG + extração de briefing.
        """
        
        # Template com constraints explícitas
        prompt_template = ChatPromptTemplate.from_template("""
        Você é um assistente de atendimento ao cliente de uma agência de turismo premium.
        
        BASE DE CONHECIMENTO DA EMPRESA:
        {rag_context}
        
        HISTÓRICO DA CONVERSA:
        {conversation_history}
        
        MENSAGEM DO CLIENTE:
        {user_message}
        
        INSTRUÇÕES CRÍTICAS:
        1. NUNCA gere preços, valores ou orçamentos. Se perguntarem sobre preço, diga: "Vou conectar com um consultor para oferecer a melhor proposta"
        2. NUNCA prometa nada não confirmado pela empresa
        3. Responda com entusiasmo e profissionalismo
        4. Se não souber, sempre ofereça conectar com um consultor
        5. Extraia informações do cliente sem fazer perguntas pressão
        
        RESPONDA EM PORTUGUÊS CLARO E AMIGÁVEL.
        
        Sua resposta deve:
        A) Responder à pergunta do cliente
        B) Extrair dados estruturados do briefing em JSON ao final
        
        Exemplo final:
        "Que legal! Vou agendar uma curadoria com nossa equipe..."
        
        DADOS_EXTRAIDOS:
        {{
            "destination": "...",
            "departure_date": "...",
            ...
        }}
        """)
        
        # Construir histórico
        conversation_history = "\n".join([
            f"Cliente: {msg['content']}" if msg['role'] == 'user' else f"Assistente: {msg['content']}"
            for msg in history[-5:]  # Últimas 5 mensagens
        ])
        
        # Executar chain
        chain = (
            {
                "rag_context": RunnablePassthrough(),
                "conversation_history": RunnablePassthrough(),
                "user_message": RunnablePassthrough(),
            }
            | prompt_template
            | self.llm
        )
        
        response = chain.invoke({
            "rag_context": rag_context,
            "conversation_history": conversation_history,
            "user_message": user_message,
        })
        
        response_text = response.content
        
        # Extrair JSON
        briefing = self._parse_briefing_json(response_text)
        
        return response_text, briefing
    
    def _parse_briefing_json(self, response_text: str) -> dict:
        """
        Extrai JSON de dados estruturados da resposta.
        """
        import re, json
        
        match = re.search(r'DADOS_EXTRAIDOS:\s*({.*})', response_text, re.DOTALL)
        if not match:
            return {}
        
        try:
            json_str = match.group(1)
            briefing = json.loads(json_str)
            return briefing
        except json.JSONDecodeError:
            logger.warning("Failed to parse briefing JSON")
            return {}
    
    def _contains_pricing(self, text: str) -> bool:
        """
        Detecta se resposta contém preços (BLOQUEADOR).
        """
        import re
        patterns = [
            r'R\$\s*[\d.,]+',
            r'custa\s+',
            r'preço de',
        ]
        return any(re.search(p, text, re.IGNORECASE) for p in patterns)
    
    def _get_safe_fallback(self, text: str) -> str:
        """Substitui resposta com preço por resposta segura."""
        return "Excelente! Para oferecer a proposta mais competitiva, vou conectar com nosso consultor de viagens. Qual melhor horário para contato?"
    
    def _get_error_fallback(self) -> str:
        """Resposta em caso de erro."""
        return "Desculpe, tive um problema técnico. Vou conectar você com um consultor. Obrigado!"
    
    async def _store_conversation_memory(
        self,
        conversation_id: str,
        user_message: str,
        ai_response: str,
        briefing: dict,
    ):
        """
        Armazena conversa para memória futura (RAG).
        """
        # Implementar conforme BD (MongoDB, PostgreSQL, etc)
        pass
```

---

## 4. FIREBASE FCM — Notificações Push

### ✅ Padrão Correto — Notificação em < 2s

```python
# backend/services/notification_service.py
from firebase_admin import messaging
import firebase_admin
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

class NotificationService:
    def __init__(self):
        # Firebase já inicializado em main.py
        self.app = firebase_admin.get_app()
    
    @staticmethod
    async def notify_consultant_new_lead(
        consultant_user_id: str,
        lead_id: str,
        lead_data: dict,
    ) -> bool:
        """
        Envia notificação push ao consultor quando novo lead chega.
        REGRA: Deve ser entregue em < 2 segundos.
        """
        try:
            # 1. Obter device token do consultor (do banco)
            device_tokens = get_consultant_device_tokens(consultant_user_id)
            if not device_tokens:
                logger.warning(f"No device tokens for consultant {consultant_user_id}")
                return False
            
            # 2. Preparar payload
            destination = lead_data.get("briefing", {}).get("destination", "Sem destino")
            score = lead_data.get("score", 0)
            
            notification_payload = messaging.Notification(
                title="🔔 Novo Lead Recebido",
                body=f"{destination} | Score: {score}/10",
            )
            
            data_payload = {
                "lead_id": str(lead_id),
                "action": "open_lead",
                "timestamp": datetime.utcnow().isoformat(),
            }
            
            # 3. Enviar via FCM
            response = messaging.send_multicast(
                messaging.MulticastMessage(
                    notification=notification_payload,
                    data=data_payload,
                    tokens=device_tokens,
                )
            )
            
            # 4. Log resultado
            logger.info(
                f"FCM sent to {consultant_user_id} | "
                f"Success: {response.success_count} | "
                f"Failure: {response.failure_count}"
            )
            
            # 5. Armazenar em auditoria
            store_notification_audit(
                user_id=consultant_user_id,
                lead_id=str(lead_id),
                status="sent",
                success_count=response.success_count,
                failure_count=response.failure_count,
            )
            
            return response.success_count > 0
        
        except Exception as e:
            logger.error(f"FCM error: {e}", exc_info=True)
            return False
    
    @staticmethod
    def subscribe_to_leads_topic(device_token: str, consultant_id: str):
        """
        Inscreve dispositivo em tópico de novos leads.
        Alternativa a device tokens individuais.
        """
        try:
            topic = f"leads_{consultant_id}"
            response = messaging.subscribe_to_topic(device_token, topic)
            logger.info(f"Device subscribed to topic: {topic}")
            return True
        except Exception as e:
            logger.error(f"Subscribe error: {e}")
            return False


def get_consultant_device_tokens(consultant_user_id: str) -> list:
    """Busca todos os device tokens do consultor (app instalado em múltiplos dispositivos)."""
    # Implementar conforme BD
    pass

def store_notification_audit(user_id: str, lead_id: str, status: str, success_count: int, failure_count: int):
    """Registra auditoria de notificações enviadas."""
    # Implementar conforme BD
    pass
```

---

## 5. MODELO DE BANCO DE DADOS

### ✅ Schema Obrigatório (SQLAlchemy)

```python
# backend/models/schemas.py
from sqlalchemy import Column, String, Integer, DateTime, Float, JSON, Boolean, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    
    id = Column(String(36), primary_key=True)
    email = Column(String(255), unique=True, index=True)
    password_hash = Column(String(255))  # bcrypt hash
    role = Column(String(20))  # admin, consultant, client
    phone = Column(String(20))
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Conversation(Base):
    __tablename__ = "conversations"
    
    id = Column(String(36), primary_key=True)
    user_id = Column(String(36), ForeignKey("users.id"))
    user_phone = Column(String(20), index=True)
    whatsapp_id = Column(String(20), unique=True)
    status = Column(String(20))  # active, closed
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class ConversationMessage(Base):
    __tablename__ = "conversation_messages"
    
    id = Column(String(36), primary_key=True)
    conversation_id = Column(String(36), ForeignKey("conversations.id"), index=True)
    sender = Column(String(20))  # user, assistant, system
    content = Column(String(4000))
    message_type = Column(String(20))  # text, image, audio
    metadata = Column(JSON)  # dados adicionais
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)


class Lead(Base):
    __tablename__ = "leads"
    
    id = Column(String(36), primary_key=True)
    conversation_id = Column(String(36), ForeignKey("conversations.id"), index=True)
    user_id = Column(String(36), ForeignKey("users.id"))
    briefing_data = Column(JSON)  # dados estruturados
    score = Column(Float, default=0)  # 0-10
    status = Column(String(20), default="new")  # new, qualified, in_curation, closed
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Notification(Base):
    __tablename__ = "notifications"
    
    id = Column(String(36), primary_key=True)
    user_id = Column(String(36), ForeignKey("users.id"), index=True)
    lead_id = Column(String(36), ForeignKey("leads.id"))
    type = Column(String(50))  # new_lead, follow_up_needed
    read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class AuditLog(Base):
    __tablename__ = "audit_log"
    
    id = Column(String(36), primary_key=True)
    action = Column(String(100), index=True)  # login, create_lead, modify_lead
    user_id = Column(String(36), ForeignKey("users.id"))
    resource_type = Column(String(50))  # lead, user, conversation
    resource_id = Column(String(36))
    details = Column(JSON)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)
```

---

## 6. TESTES — Padrão com Pytest

### ✅ Testes Obrigatórios

```python
# backend/tests/test_webhook.py
import pytest
from fastapi.testclient import TestClient
from main import app
import json

client = TestClient(app)

class TestWebhook:
    
    def test_webhook_responds_in_time(self):
        """
        TESTE CRÍTICO: Webhook deve responder em < 5s
        """
        payload = {
            "entry": [{
                "changes": [{
                    "field": "messages",
                    "value": {
                        "messages": [{
                            "from": "5585988012345",
                            "id": "msg123",
                            "timestamp": "1234567890",
                            "type": "text",
                            "text": {"body": "Olá"},
                        }]
                    }
                }]
            }]
        }
        
        # Simular request
        import time
        start = time.time()
        response = client.post(
            "/webhook/whatsapp",
            json=payload,
            headers={"X-Verify-Token": "correct_token"},
        )
        elapsed = time.time() - start
        
        # Assertions
        assert response.status_code == 200
        assert elapsed < 5.0, f"Webhook took {elapsed}s, must be < 5s"
    
    def test_webhook_rejects_invalid_verify_token(self):
        """Webhook rejeita token inválido"""
        payload = {"entry": [{"changes": []}]}
        
        response = client.post(
            "/webhook/whatsapp",
            json=payload,
            headers={"X-Verify-Token": "wrong_token"},
        )
        
        assert response.status_code == 403
    
    def test_conversation_log_created_on_message(self):
        """Cada mensagem cria um ConversationLog (fallback)"""
        payload = {
            "entry": [{
                "changes": [{
                    "field": "messages",
                    "value": {
                        "messages": [{
                            "from": "5585988012345",
                            "id": "msg456",
                            "timestamp": "1234567890",
                            "type": "text",
                            "text": {"body": "Teste"},
                        }]
                    }
                }]
            }]
        }
        
        response = client.post(
            "/webhook/whatsapp",
            json=payload,
            headers={"X-Verify-Token": "correct_token"},
        )
        
        assert response.status_code == 200
        
        # Verificar se log foi criado
        log = ConversationLog.find_one({"whatsapp_message_id": "msg456"})
        assert log is not None


class TestJWT:
    
    def test_create_and_verify_token(self):
        """JWT: criar e validar"""
        from utils.security import JWTHandler
        
        tokens = JWTHandler.create_tokens("user123", "consultant")
        assert tokens["access_token"]
        assert tokens["refresh_token"]
        
        # Validar
        payload = JWTHandler.verify_token(tokens["access_token"])
        assert payload["sub"] == "user123"
    
    def test_expired_token_rejected(self):
        """JWT: token expirado rejeitado"""
        from utils.security import JWTHandler
        import time
        
        # (em testes, poderia mockar tempo)
        # Token expirado deve lançar erro
        pass


class TestAI:
    
    def test_ai_responds_without_pricing(self):
        """IA: NUNCA deve gerar preços"""
        from services.ai_service import AIService
        
        ai = AIService()
        response, briefing = asyncio.run(
            ai.process_message(
                conversation_id="test123",
                user_message="Quanto custa uma viagem para Maldivas?",
            )
        )
        
        # Verificar que NOT contém "R$" ou "preço"
        assert "R$" not in response
        assert "preço" not in response.lower()
        assert "consultor" in response.lower()  # Deve oferecer consultor
    
    def test_ai_extracts_briefing(self):
        """IA: extrai briefing corretamente"""
        response, briefing = asyncio.run(
            ai.process_message(
                conversation_id="test123",
                user_message="Quero ir para Maldivas no Carnaval com minha esposa e dois filhos",
            )
        )
        
        assert briefing is not None
        assert briefing.get("destination") == "Maldivas"
        assert briefing.get("num_people") == 4
```

---

## 7. LOGGING ESTRUTURADO

### ✅ Padrão

```python
# backend/config.py
import logging
from logging.handlers import RotatingFileHandler
import json

# JSON logging (para centralizar)
class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_data = {
            "timestamp": self.formatTime(record),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
        }
        
        if record.exc_info:
            log_data["exception"] = self.formatException(record.exc_info)
        
        return json.dumps(log_data, ensure_ascii=False)


def setup_logging():
    """Setup logging estruturado"""
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    
    # Arquivo de log rotativo
    handler = RotatingFileHandler(
        "app.log",
        maxBytes=10*1024*1024,  # 10MB
        backupCount=5,
    )
    handler.setFormatter(JSONFormatter())
    logger.addHandler(handler)
    
    # Console também
    console = logging.StreamHandler()
    console.setFormatter(JSONFormatter())
    logger.addHandler(console)


# Usar em logging
logger = logging.getLogger(__name__)

logger.info("Lead criado", extra={
    "lead_id": "lead123",
    "user_id": "user456",
    "score": 7.5,
})

logger.error("Erro crítico", extra={
    "action": "create_lead",
    "error_type": "database_error",
}, exc_info=True)
```

---

## 8. VALIDAÇÃO COM PYDANTIC

### ✅ Padrão

```python
# backend/schemas/lead.py
from pydantic import BaseModel, Field, validator
from typing import Optional
from datetime import date

class BriefingInput(BaseModel):
    destination: Optional[str] = Field(None, min_length=2, max_length=100)
    departure_date: Optional[date] = None
    return_date: Optional[date] = None
    num_people: Optional[int] = Field(None, ge=1, le=20)
    budget_range: Optional[str] = Field(None, regex=r"^\d+-\d+$")  # "5000-10000"
    travel_type: Optional[str] = Field(None, regex="^(lazer|negócio|lua-de-mel)$")
    
    class Config:
        json_schema_extra = {
            "example": {
                "destination": "Maldivas",
                "departure_date": "2025-06-15",
                "num_people": 4,
            }
        }
    
    @validator("return_date")
    def return_after_departure(cls, v, values):
        if v and "departure_date" in values and v < values["departure_date"]:
            raise ValueError("return_date must be after departure_date")
        return v


class LeadResponse(BaseModel):
    id: str
    score: float
    status: str
    briefing_data: BriefingInput
    created_at: str


# Usar em endpoint
@router.post("/leads", response_model=LeadResponse)
async def create_lead(briefing: BriefingInput):
    # Pydantic já validou automaticamente
    lead = await lead_service.create(briefing.dict())
    return LeadResponse(**lead)
```

---

## SUMÁRIO DE CHECKLIST PRÉ-COMMIT

```bash
# Antes de fazer commit, rodar:

# 1. Linting
flake8 backend/ --max-line-length=100

# 2. Type checking
mypy backend/

# 3. Tests
pytest backend/tests/ -v

# 4. Security (credenciais)
grep -r "password\|secret\|api_key" backend/ --include="*.py" | grep -v ".env"

# 5. Remover debug
grep -r "print(\|console.log(\|debugger" backend/ --include="*.py"

# 6. Commit
git commit -m "feat: descrição clara e concisa"
```

---

Versão 1.0 — Junho 2025  
Mantenido por: Tech Lead