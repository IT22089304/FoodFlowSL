from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, create_access_token, get_jwt_identity
from werkzeug.security import generate_password_hash, check_password_hash
from bson import ObjectId
from app.utils.db import mongo
from datetime import datetime

auth_bp = Blueprint('auth', __name__)

# ✅ Register new user
@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    existing = mongo.db.users.find_one({'email': data['email']})
    if existing:
        return jsonify({'error': 'User already exists'}), 400

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
    return jsonify({'message': 'User registered successfully'}), 201

# ✅ Login user
@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    user = mongo.db.users.find_one({'email': data['email']})
    if not user or not check_password_hash(user['password'], data['password']):
        return jsonify({'message': 'Invalid credentials'}), 401

    token = create_access_token(identity=str(user['_id']))
    return jsonify({
        'token': token,
        'role': user['role'],
        'userId': str(user['_id'])
    })

# ✅ Get logged-in user's profile
@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def get_profile():
    user_id = get_jwt_identity()
    user = mongo.db.users.find_one({'_id': ObjectId(user_id)}, {'password': 0})
    if not user:
        return jsonify({'error': 'User not found'}), 404
    user['_id'] = str(user['_id'])
    return jsonify(user)

# ✅ Update user profile
@auth_bp.route('/update', methods=['PUT'])
@jwt_required()
def update_profile():
    user_id = get_jwt_identity()
    data = request.get_json()
    updates = {}

    if 'name' in data:
        updates['name'] = data['name']
    if 'password' in data:
        updates['password'] = generate_password_hash(data['password'])
    if 'role' in data:
        updates['role'] = data['role']
    if 'location' in data:
        updates['location'] = data['location']
    if 'profilePic' in data:
        updates['profilePic'] = data['profilePic']
    if 'mobileNumber' in data:
        updates['mobileNumber'] = data['mobileNumber']  # ✅ New field

    updated = mongo.db.users.find_one_and_update(
        {'_id': ObjectId(user_id)},
        {'$set': updates},
        return_document=True
    )

    return jsonify({'message': 'Profile updated', 'user': str(updated)})

# ✅ Delete user account
@auth_bp.route('/delete', methods=['DELETE'])
@jwt_required()
def delete_account():
    user_id = get_jwt_identity()
    mongo.db.users.delete_one({'_id': ObjectId(user_id)})
    return jsonify({'message': 'Account deleted successfully'})

@auth_bp.route('/users/<string:user_id>', methods=['GET'])
@jwt_required()
def get_user_by_id(user_id):
    user = mongo.db.users.find_one({'_id': ObjectId(user_id)}, {'password': 0})
    if not user:
        return jsonify({'error': 'User not found'}), 404
    user['_id'] = str(user['_id'])
    return jsonify(user), 200
