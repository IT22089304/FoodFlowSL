from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime
from pymongo import MongoClient
from pytz import timezone

def expire_donations():
    now = datetime.now(timezone('Asia/Colombo'))
    print(f"[{now}] 🔍 Scanning for expired donations...")

    client = MongoClient("mongodb+srv://lahiruflutter:lahiru@cluster0.oxqke.mongodb.net/flutter414?retryWrites=true&w=majority&appName=Cluster0")
    db = client["flutter414"]
    donations = db["donations"]

    result = donations.update_many(
        {"status": "pending", "expiresAt": {"$lt": now}},
        {"$set": {"status": "expired"}}
    )

    print(f"[{now}] ✅ Marked {result.modified_count} donations as expired.")

def start_scheduler():
    scheduler = BackgroundScheduler()
    scheduler.add_job(expire_donations, trigger="interval", minutes=1)
    scheduler.start()
    print("📆 Donation expiration scheduler started — running every minute.")
