from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from bson import ObjectId
from datetime import datetime
from app.utils.db import mongo

notification_bp = Blueprint('notification', __name__)

# ✅ Recursive Serializer
def serialize_document(doc):
    if isinstance(doc, list):
        return [serialize_document(item) if isinstance(item, (dict, list)) else str(item) if isinstance(item, ObjectId) else item for item in doc]
    if isinstance(doc, dict):
        for key, value in doc.items():
            if isinstance(value, ObjectId):
                doc[key] = str(value)
            elif isinstance(value, datetime):
                doc[key] = value.isoformat()
            elif isinstance(value, (dict, list)):
                doc[key] = serialize_document(value)
    return doc

# ✅ Create Notification via API
@notification_bp.route('', methods=['POST'])
@jwt_required()
def create_notification_api():
    try:
        data = request.get_json()
        print(f"📢 Creating notification: {data}")

        notification = {
            'user': ObjectId(data['user']),
            'message': data['message'],
            'type': data.get('type', 'info'),
            'isRead': False,
            'createdAt': datetime.utcnow(),
        }

        for field in ['targetDonationId', 'targetDonationTitle', 'targetDonationImage']:
            if field in data:
                notification[field] = data[field]

        mongo.db.notifications.insert_one(notification)
        notification = serialize_document(notification)

        print(f"✅ Notification created: {notification}")
        return jsonify({'message': 'Notification created successfully', 'notification': notification}), 201

    except Exception as e:
        print(f"❌ Error creating notification: {e}")
        return jsonify({'error': 'Failed to create notification', 'details': str(e)}), 500

# ✅ Get All Notifications for Current User
@notification_bp.route('', methods=['GET'])
@jwt_required()
def get_notifications():
    try:
        user_id = get_jwt_identity()
        print(f"📢 Fetching notifications for User ID: {user_id}")

        notifications = list(mongo.db.notifications.find({'user': ObjectId(user_id)}).sort('createdAt', -1))
        notifications = serialize_document(notifications)

        print(f"✅ Retrieved Notifications: {notifications}")
        return jsonify(notifications), 200

    except Exception as e:
        print(f"❌ Error fetching notifications: {e}")
        return jsonify({'error': 'Failed to fetch notifications', 'details': str(e)}), 500

# ✅ Mark a Notification as Read
@notification_bp.route('/<string:notification_id>/read', methods=['PUT'])
@jwt_required()
def mark_as_read(notification_id):
    try:
        user_id = get_jwt_identity()
        print(f"📢 Marking notification {notification_id} as read for User ID: {user_id}")

        result = mongo.db.notifications.find_one_and_update(
            {'_id': ObjectId(notification_id), 'user': ObjectId(user_id)},
            {'$set': {'isRead': True}},
            return_document=True
        )

        if not result:
            return jsonify({'error': 'Notification not found'}), 404

        result = serialize_document(result)
        print(f"✅ Notification marked as read: {result}")
        return jsonify(result), 200

    except Exception as e:
        print(f"❌ Error marking notification as read: {e}")
        return jsonify({'error': 'Failed to mark as read', 'details': str(e)}), 500

# ✅ Delete a Notification
@notification_bp.route('/<string:notification_id>', methods=['DELETE'])
@jwt_required()
def delete_notification(notification_id):
    try:
        user_id = get_jwt_identity()
        print(f"📢 Deleting notification {notification_id} for User ID: {user_id}")

        result = mongo.db.notifications.delete_one({
            '_id': ObjectId(notification_id),
            'user': ObjectId(user_id)
        })

        if result.deleted_count == 0:
            return jsonify({'error': 'Notification not found'}), 404

        print("✅ Notification deleted successfully")
        return jsonify({'message': 'Notification deleted'}), 200

    except Exception as e:
        print(f"❌ Error deleting notification: {e}")
        return jsonify({'error': 'Failed to delete notification', 'details': str(e)}), 500
