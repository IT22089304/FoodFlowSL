from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, create_access_token, get_jwt_identity
from werkzeug.security import generate_password_hash, check_password_hash
from bson import ObjectId
from app.utils.db import mongo
from datetime import datetime

auth_bp = Blueprint('auth', __name__)

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

# ✅ Register New User
@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    required_fields = ['name', 'email', 'password', 'role']
    if not all(field in data for field in required_fields):
        return jsonify({'error': 'Missing required fields'}), 400

    if mongo.db.users.find_one({'email': data['email']}):
        return jsonify({'error': 'User already exists'}), 400

    if len(data['password']) < 6:
        return jsonify({'error': 'Password must be at least 6 characters long'}), 400

    hashed_pw = generate_password_hash(data['password'])
    new_user = {
        'name': data['name'],
        'email': data['email'],
        'password': hashed_pw,
        'role': data['role'],
        'profilePic': data.get('profilePic', ''),
        'location': data.get('location', {}),
        'createdAt': datetime.utcnow()
    }
    mongo.db.users.insert_one(new_user)
    print(f"✅ User Registered: {data['email']}")
    return jsonify({'message': 'User registered successfully'}), 201

# ✅ Login User
@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    if 'email' not in data or 'password' not in data:
        return jsonify({'error': 'Email and password are required'}), 400

    user = mongo.db.users.find_one({'email': data['email']})
    if not user or not check_password_hash(user['password'], data['password']):
        return jsonify({'error': 'Invalid credentials'}), 401

    token = create_access_token(identity=str(user['_id']))
    print(f"✅ User Logged In: {data['email']}")
    return jsonify({
        'token': token,
        'role': user['role'],
        'userId': str(user['_id'])
    }), 200

# ✅ Get Current User Profile
@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def get_profile():
    user_id = get_jwt_identity()
    user = mongo.db.users.find_one({'_id': ObjectId(user_id)}, {'password': 0})
    if not user:
        return jsonify({'error': 'User not found'}), 404
    return jsonify(serialize_document(user)), 200

# ✅ Update User Profile
@auth_bp.route('/update', methods=['PUT'])
@jwt_required()
def update_profile():
    user_id = get_jwt_identity()
    data = request.get_json()
    updates = {}

    for field in ['name', 'role', 'location', 'profilePic', 'mobileNumber']:
        if field in data:
            updates[field] = data[field]

    if 'password' in data:
        if len(data['password']) < 6:
            return jsonify({'error': 'Password must be at least 6 characters long'}), 400
        updates['password'] = generate_password_hash(data['password'])

    updates['updatedAt'] = datetime.utcnow()

    updated_user = mongo.db.users.find_one_and_update(
        {'_id': ObjectId(user_id)},
        {'$set': updates},
        return_document=True
    )

    if not updated_user:
        return jsonify({'error': 'User not found'}), 404

    print(f"✅ User Updated: {user_id}")
    return jsonify({'message': 'Profile updated', 'user': serialize_document(updated_user)}), 200

# ✅ Delete Account
@auth_bp.route('/delete', methods=['DELETE'])
@jwt_required()
def delete_account():
    user_id = get_jwt_identity()
    result = mongo.db.users.delete_one({'_id': ObjectId(user_id)})

    if result.deleted_count == 0:
        return jsonify({'error': 'User not found'}), 404

    print(f"🗑️ User Account Deleted: {user_id}")
    return jsonify({'message': 'Account deleted successfully'}), 200

# ✅ Get User by ID
@auth_bp.route('/users/<string:user_id>', methods=['GET'])
@jwt_required()
def get_user_by_id(user_id):
    user = mongo.db.users.find_one({'_id': ObjectId(user_id)}, {'password': 0})
    if not user:
        return jsonify({'error': 'User not found'}), 404
    return jsonify(serialize_document(user)), 200
