from app.utils.db import mongo

# Access like: mongo.db.orders
# Fields:
# - donationId, receiverId, volunteerId
# - status: 'claimed' | 'in-transit' | 'delivered'
# - claimedAt, deliveredAt, createdAt
