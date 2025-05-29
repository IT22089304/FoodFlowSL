from app.utils.db import mongo

# Access like: mongo.db.donations
# Fields:
# - donorId, description, quantity, expiresAt, location, image, claimedBy
# - status: 'pending' | 'claimed' | 'confirmed' | 'expired'
# - confirmedAt, createdAt
