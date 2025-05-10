from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from bson import ObjectId
from datetime import datetime
from app.utils.db import mongo

notification_bp = Blueprint('notification', __name__)

# ✅ Create a notification (can be protected if needed)
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from bson import ObjectId
from datetime import datetime
from app.utils.db import mongo

# ✅ Create notification via API
@notification_bp.route('', methods=['POST'])
@jwt_required()
def create_notification_api():
    try:
        data = request.get_json()

        notification = {
            'user': ObjectId(data['user']),
            'message': data['message'],
            'type': data.get('type', 'info'),
            'isRead': False,
            'createdAt': datetime.utcnow(),
        }

        if 'targetDonationId' in data:
            notification['targetDonationId'] = data['targetDonationId']
        if 'targetDonationTitle' in data:
            notification['targetDonationTitle'] = data['targetDonationTitle']
        if 'targetDonationImage' in data:
            notification['targetDonationImage'] = data['targetDonationImage']

        mongo.db.notifications.insert_one(notification)

        return jsonify({'message': 'Notification created successfully'}), 201
    except Exception as e:
        print(f"Error creating notification: {e}")
        return jsonify({'error': 'Failed to create notification'}), 500



# ✅ Get all notifications for current user
@notification_bp.route('', methods=['GET'])
@jwt_required()
def get_notifications():
    user_id = get_jwt_identity()
    notifications = list(mongo.db.notifications.find({'user': ObjectId(user_id)}).sort('createdAt', -1))
    for n in notifications:
        n['_id'] = str(n['_id'])
        n['user'] = str(n['user'])
    return jsonify(notifications)

# ✅ Mark a notification as read
@notification_bp.route('/<string:notification_id>/read', methods=['PUT'])
@jwt_required()
def mark_as_read(notification_id):
    user_id = get_jwt_identity()
    result = mongo.db.notifications.find_one_and_update(
        {'_id': ObjectId(notification_id), 'user': ObjectId(user_id)},
        {'$set': {'isRead': True}},
        return_document=True
    )
    if not result:
        return jsonify({'error': 'Notification not found'}), 404
    result['_id'] = str(result['_id'])
    return jsonify(result)

# ✅ Delete a notification
@notification_bp.route('/<string:notification_id>', methods=['DELETE'])
@jwt_required()
def delete_notification(notification_id):
    user_id = get_jwt_identity()
    result = mongo.db.notifications.delete_one({
        '_id': ObjectId(notification_id),
        'user': ObjectId(user_id)
    })
    if result.deleted_count == 0:
        return jsonify({'error': 'Notification not found'}), 404
    return jsonify({'message': 'Notification deleted'})
