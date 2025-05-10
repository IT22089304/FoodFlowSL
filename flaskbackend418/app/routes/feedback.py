from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from bson import ObjectId
from datetime import datetime
from app.utils.db import mongo

feedback_bp = Blueprint('feedback', __name__)

# ✅ Leave feedback for a donor or volunteer
@feedback_bp.route('/', methods=['POST'])
@jwt_required()
def leave_feedback():
    user_id = get_jwt_identity()
    data = request.get_json()
    feedback = {
        'user': ObjectId(user_id),            # who left the feedback
        'target': ObjectId(data['target']),   # the person being reviewed
        'type': data['type'],                 # 'donor' or 'volunteer'
        'rating': data['rating'],             # 1-5
        'comment': data.get('comment', ''),
        'createdAt': datetime.utcnow()
    }
    mongo.db.feedback.insert_one(feedback)
    feedback['_id'] = str(feedback['_id'])
    return jsonify({'message': 'Feedback submitted', 'feedback': feedback}), 201

# ✅ Get feedback for a specific user
@feedback_bp.route('/<string:user_id>', methods=['GET'])
def get_feedback_for_user(user_id):
    feedbacks = list(mongo.db.feedback.find({'target': ObjectId(user_id)}))
    for fb in feedbacks:
        fb['_id'] = str(fb['_id'])
        fb['user'] = str(fb['user'])
        fb['target'] = str(fb['target'])
    return jsonify(feedbacks)
