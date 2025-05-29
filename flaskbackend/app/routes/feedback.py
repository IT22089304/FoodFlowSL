from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from bson import ObjectId
from datetime import datetime
from app.utils.db import mongo

feedback_bp = Blueprint('feedback', __name__)

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

# ✅ Leave Feedback
@feedback_bp.route('/', methods=['POST'])
@jwt_required()
def leave_feedback():
    try:
        user_id = get_jwt_identity()
        print(f"📢 Feedback submitted by User ID: {user_id}")
        data = request.get_json()

        required_fields = ['target', 'type', 'rating']
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400

        if not (1 <= data['rating'] <= 5):
            return jsonify({'error': 'Rating must be between 1 and 5'}), 400

        feedback = {
            'user': ObjectId(user_id),
            'target': ObjectId(data['target']),
            'type': data['type'],
            'rating': data['rating'],
            'comment': data.get('comment', ''),
            'createdAt': datetime.utcnow()
        }

        mongo.db.feedback.insert_one(feedback)
        feedback = serialize_document(feedback)

        print(f"✅ Feedback submitted: {feedback}")
        return jsonify({'message': 'Feedback submitted', 'feedback': feedback}), 201

    except Exception as e:
        print(f"❌ Error submitting feedback: {e}")
        return jsonify({'error': 'Failed to submit feedback', 'details': str(e)}), 500

# ✅ Get Feedback for a Specific User
@feedback_bp.route('/<string:user_id>', methods=['GET'])
@jwt_required()
def get_feedback_for_user(user_id):
    try:
        print(f"📢 Fetching feedback for User ID: {user_id}")
        feedbacks = list(mongo.db.feedback.find({'target': ObjectId(user_id)}))
        feedbacks = serialize_document(feedbacks)
        print(f"✅ Retrieved Feedbacks: {feedbacks}")
        return jsonify(feedbacks), 200

    except Exception as e:
        print(f"❌ Error fetching feedback: {e}")
        return jsonify({'error': 'Failed to fetch feedback', 'details': str(e)}), 500
