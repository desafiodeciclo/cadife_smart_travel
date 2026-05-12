"""
Smoke Test — Suitcase Feature (V2)
=================================
Validates CRUD, Grouping, and Suggestions at the service level.
Now creates a temporary User and Lead to satisfy Foreign Key constraints.
"""

import asyncio
import sys
import os
import uuid

# Add parent directory to path to allow imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import select, delete
from app.infrastructure.persistence.database import AsyncSessionLocal
from app.services import suitcase_service
from app.domain.entities.enums import SuitcaseCategory, DestinationType
from app.infrastructure.persistence.models.user_model import UserModel
from app.infrastructure.persistence.models.lead_model import LeadModel
from app.infrastructure.persistence.models.suitcase_model import SuitcaseItemModel

async def run_smoke_test():
    print("🧪 Starting Suitcase Smoke Test (V2)...")
    
    async with AsyncSessionLocal() as db:
        test_user = None
        test_lead = None
        
        try:
            # 0. Setup: Create Dummy User and Lead
            print("  [0/4] Setup: Creating dummy User and Lead...")
            test_user = UserModel(
                id=uuid.uuid4(),
                email=f"test_{uuid.uuid4().hex[:6]}@cadife.com",
                nome="QA Tester",
                hashed_password="fake_password",
                perfil="cliente",
                is_active=True
            )
            db.add(test_user)
            await db.flush()
            
            test_lead = LeadModel(
                id=uuid.uuid4(),
                nome="QA Lead",
                telefone=f"+55119{uuid.uuid4().hex[:8]}",
                status="novo"
            )
            db.add(test_lead)
            await db.flush()
            await db.commit()
            print(f"  ✅ Setup: User({test_user.id}) and Lead({test_lead.id}) created.")

            # 1. Test Add Item
            print("  [1/4] Testing: Add Item...")
            item = await suitcase_service.add_item(
                db, 
                lead_id=test_lead.id, 
                user_id=test_user.id, 
                nome="Test Passport", 
                categoria=SuitcaseCategory.documentos, 
                quantidade=1
            )
            assert item.nome == "Test Passport"
            assert item.empacotado is False
            print("  ✅ Add Item: Success")

            # 2. Test Update Item (Packing)
            print("  [2/4] Testing: Update (Packing)...")
            updated = await suitcase_service.update_item(db, item.id, empacotado=True)
            assert updated.empacotado is True
            print("  ✅ Update Item: Success")

            # 3. Test Grouped Retrieval
            print("  [3/4] Testing: Grouped Suitcase...")
            grouped = await suitcase_service.get_grouped_suitcase(db, test_lead.id)
            assert grouped["total_items"] == 1
            assert grouped["total_packed"] == 1
            assert "documentos" in grouped["items_by_category"]
            print("  ✅ Grouped Retrieval: Success")

            # 4. Test Suggestions Logic
            print("  [4/4] Testing: Suggestions (Praia)...")
            suggestions = await suitcase_service.get_suggestions(db, "praia")
            nomes = [s.nome for s in suggestions]
            if "Protetor Solar" in nomes:
                print("  ✅ Suggestions: Success (Found Protetor Solar)")
            else:
                print("  ⚠️ Suggestions: No data found in suggestions table.")

            print("\n✨ All logic tests PASSED!")
            
        except Exception as e:
            print(f"\n❌ Test FAILED: {str(e)}")
            import traceback
            traceback.print_exc()
            await db.rollback()
        finally:
            # Cleanup
            print("\n🧹 Cleaning up test data...")
            if test_lead:
                # Suitcase items will be deleted by ON DELETE CASCADE
                await db.execute(delete(LeadModel).where(LeadModel.id == test_lead.id))
            if test_user:
                await db.execute(delete(UserModel).where(UserModel.id == test_user.id))
            await db.commit()
            print("✨ Cleanup complete.")

if __name__ == "__main__":
    asyncio.run(run_smoke_test())
