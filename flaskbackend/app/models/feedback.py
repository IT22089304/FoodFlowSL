from app.utils.db import mongo

# Access like: mongo.db.feedback
# Fields:
# - user (who left the feedback)
# - target (who it’s about)
# - type: 'donor' | 'volunteer'
# - rating (1-5), comment, createdAt
