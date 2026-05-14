import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.infrastructure.persistence.models.sale_goal_model import SaleGoalModel
from datetime import date
from dateutil.relativedelta import relativedelta

async def get_user_goals(db: AsyncSession, user_id: uuid.UUID, months: int = 3):
    # Calculate start and end dates
    today = date.today()
    end_date = today.replace(day=1)
    start_date = end_date - relativedelta(months=months - 1)
    
    # Query goals in range
    # In a real SQL query we'd compare year/month tuples
    # For simplicity and cross-DB compatibility:
    q = select(SaleGoalModel).where(
        SaleGoalModel.user_id == user_id
    ).order_by(SaleGoalModel.period_year.desc(), SaleGoalModel.period_month.desc())
    
    res = await db.execute(q)
    rows = res.scalars().all()
    
    # Filter and backfill
    results = []
    current = end_date
    for _ in range(months):
        year, month = current.year, current.month
        # Find if we have a row for this month
        match = next((r for r in rows if r.period_year == year and r.period_month == month), None)
        
        if match:
            results.append({
                "period_year": match.period_year,
                "period_month": match.period_month,
                "target": match.target,
                "achieved": match.achieved
            })
        else:
            results.append({
                "period_year": year,
                "period_month": month,
                "target": 0,
                "achieved": 0
            })
        current -= relativedelta(months=1)
        
    return results
