# app/utils/notification_service.py

from bson import ObjectId
from datetime import datetime
from app.utils.db import mongo

def create_notification(user_id, message, notif_type='info', donation=None, with_image=False):
    notification = {
        'user': ObjectId(user_id),
        'message': message,
        'type': notif_type,
        'isRead': False,
        'createdAt': datetime.utcnow()
    }
    if donation:
        notification['targetDonationId'] = str(donation['_id'])
        notification['targetDonationTitle'] = donation.get('description', '')
        if with_image:
            notification['targetDonationImage'] = donation.get('image', '')

    mongo.db.notifications.insert_one(notification)
