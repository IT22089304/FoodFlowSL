from app.utils.db import mongo

# Access like: mongo.db.notifications
# Fields:
# - user, message, type: 'info' | 'alert' | 'donation'
# - isRead, createdAt
