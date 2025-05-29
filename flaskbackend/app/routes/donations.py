from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from bson import ObjectId
from datetime import datetime
from pytz import timezone
from dateutil.parser import parse as parse_date
from app.utils.db import mongo
from app.utils.notification_service import create_notification
from math import radians, cos, sin, asin, sqrt

donation_bp = Blueprint('donation', __name__)
sri_lanka_tz = timezone('Asia/Colombo')

# ✅ Serialization Helper
def serialize_document(doc):
    for key, value in doc.items():
        if isinstance(value, ObjectId):
            doc[key] = str(value)
        elif isinstance(value, datetime):
            doc[key] = value.isoformat()
        elif isinstance(value, list):
            doc[key] = [serialize_document(item) if isinstance(item, dict) else item for item in value]
        elif isinstance(value, dict):
            doc[key] = serialize_document(value)
    return doc

# ✅ Distance Calculation
def haversine(lon1, lat1, lon2, lat2):
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    return 6367 * c

# ✅ Create Donation
@donation_bp.route('/', methods=['POST'])
@jwt_required()
def create_donation():
    user_id = get_jwt_identity()
    data = request.get_json()

    if not all(k in data for k in ("description", "quantity", "location", "image", "expiresAt")):
        return jsonify({'error': 'Missing fields'}), 400

    try:
        expires_at = parse_date(data['expiresAt'])
    except Exception:
        return jsonify({'error': 'Invalid expiresAt format'}), 400

    donation = {
        'donorId': ObjectId(user_id),
        'description': data['description'],
        'quantity': data['quantity'],
        'location': data['location'],
        'image': data['image'],
        'status': 'pending',
        'expiresAt': expires_at,
        'createdAt': datetime.now(sri_lanka_tz)
    }
    mongo.db.donations.insert_one(donation)

    # Notify receivers near 20km
    for receiver in mongo.db.users.find({'role': 'receiver'}):
        if 'location' in receiver:
            rec_lat = receiver['location'].get('lat')
            rec_lng = receiver['location'].get('lng')
            if rec_lat is not None and rec_lng is not None:
                distance = haversine(donation['location']['lng'], donation['location']['lat'], rec_lng, rec_lat)
                if distance <= 20:
                    create_notification(
                        user_id=receiver['_id'],
                        message="New food donation available near you!",
                        notif_type="donation",
                        donation=donation,
                        with_image=True
                    )

    return jsonify({'message': 'Donation created and nearby receivers notified!'}), 201

# ✅ Get All Pending Donations
@donation_bp.route('/', methods=['GET'])
@jwt_required()
def get_all_donations():
    donations = list(mongo.db.donations.find({'status': 'pending'}))
    return jsonify([serialize_document(d) for d in donations])

# ✅ Get My Donations
@donation_bp.route('/my', methods=['GET'])
@jwt_required()
def get_my_donations():
    try:
        user_id = get_jwt_identity()
        print(f"📢 JWT Identity (User ID): {user_id}")

        if not ObjectId.is_valid(user_id):
            print("❌ Invalid ObjectId detected in JWT!")
            return jsonify({'error': 'Invalid user ID in token'}), 400

        donations = list(mongo.db.donations.find({'donorId': ObjectId(user_id)}))
        print(f"📦 Raw Donations from DB: {donations}")

        serialized_donations = [serialize_document(d) for d in donations]
        print(f"✅ Serialized Donations: {serialized_donations}")

        return jsonify(serialized_donations), 200

    except Exception as e:
        print(f"🔥 ERROR in /my route: {e}")
        return jsonify({'error': 'Internal Server Error', 'details': str(e)}), 500

# ✅ Claim Donation
@donation_bp.route('/<string:donation_id>/claim', methods=['PUT'])
@jwt_required()
def claim_donation(donation_id):
    user_id = get_jwt_identity()
    donation = mongo.db.donations.find_one({'_id': ObjectId(donation_id)})
    if not donation or donation['status'] != 'pending':
        return jsonify({'error': 'Donation not available'}), 400
    mongo.db.donations.update_one(
        {'_id': ObjectId(donation_id)},
        {'$set': {'claimedBy': ObjectId(user_id), 'status': 'claimed'}}
    )
    return jsonify({'message': 'Donation claimed successfully'})

# ✅ Confirm Delivery
@donation_bp.route('/confirm/<string:donation_id>', methods=['PUT'])
@jwt_required()
def confirm_donation(donation_id):
    user_id = get_jwt_identity()
    donation = mongo.db.donations.find_one({'_id': ObjectId(donation_id)})
    if not donation or str(donation.get('claimedBy')) != user_id:
        return jsonify({'error': 'Unauthorized or not claimed by you'}), 403
    mongo.db.donations.update_one(
        {'_id': ObjectId(donation_id)},
        {'$set': {'status': 'confirmed', 'confirmedAt': datetime.utcnow()}}
    )
    return jsonify({'message': 'Donation confirmed'})

# ✅ Delete Expired Donations
@donation_bp.route('/expired', methods=['DELETE'])
@jwt_required()
def delete_expired_donations():
    now = datetime.utcnow()
    result = mongo.db.donations.delete_many({'status': 'pending', 'expiresAt': {'$lt': now}})
    return jsonify({'message': f'{result.deleted_count} expired donations removed'})

# ✅ Update Donation
@donation_bp.route('/<string:donation_id>', methods=['PUT'])
@jwt_required()
def update_donation(donation_id):
    user_id = get_jwt_identity()
    data = request.get_json()
    donation = mongo.db.donations.find_one({'_id': ObjectId(donation_id), 'donorId': ObjectId(user_id)})
    if not donation:
        return jsonify({'error': 'Donation not found or unauthorized'}), 404

    updates = {}
    for field in ['description', 'quantity', 'image']:
        if field in data:
            updates[field] = data[field]
    if 'expiresAt' in data:
        try:
            updates['expiresAt'] = parse_date(data['expiresAt'])
        except Exception:
            return jsonify({'error': 'Invalid expiresAt format'}), 400

    mongo.db.donations.update_one({'_id': ObjectId(donation_id)}, {'$set': updates})
    return jsonify({'message': 'Donation updated successfully'})

# ✅ Delete Donation
@donation_bp.route('/<string:donation_id>', methods=['DELETE'])
@jwt_required()
def delete_donation(donation_id):
    user_id = get_jwt_identity()
    result = mongo.db.donations.delete_one({'_id': ObjectId(donation_id), 'donorId': ObjectId(user_id)})
    if result.deleted_count == 0:
        return jsonify({'error': 'Donation not found or unauthorized'}), 404
    return jsonify({'message': 'Donation deleted successfully'})

@donation_bp.route('/<string:donation_id>/rate', methods=['POST'])
@jwt_required()
def rate_donation(donation_id):
    user_id = get_jwt_identity()
    data = request.get_json()
    rating_value = data.get('rating')

    # Validate rating input
    if not isinstance(rating_value, int) or not (1 <= rating_value <= 5):
        return jsonify({'error': 'Rating must be an integer between 1 and 5'}), 400

    donation = mongo.db.donations.find_one({'_id': ObjectId(donation_id)})
    if not donation:
        return jsonify({'error': 'Donation not found'}), 404

    # Safely check for existing rating
    if any(isinstance(r, dict) and str(r.get('userId')) == user_id for r in donation.get('ratings', [])):
        return jsonify({'error': 'You have already rated this donation'}), 403

    mongo.db.donations.update_one(
        {'_id': ObjectId(donation_id)},
        {'$push': {'ratings': {'userId': ObjectId(user_id), 'value': rating_value}}}
    )

    return jsonify({'message': 'Rating submitted successfully'}), 200

@donation_bp.route('/<string:donation_id>/my-rating', methods=['GET'])
@jwt_required()
def get_my_rating(donation_id):
    user_id = get_jwt_identity()
    donation = mongo.db.donations.find_one({'_id': ObjectId(donation_id)})
    if not donation:
        return jsonify({'error': 'Donation not found'}), 404

    # Safely loop through ratings
    for r in donation.get('ratings', []):
        if isinstance(r, dict) and str(r.get('userId')) == user_id:
            return jsonify({'rating': r.get('value')}), 200

    return jsonify({'rating': None}), 200

# ✅ Donor Public Profile
@donation_bp.route('/donor/<string:donor_id>/profile', methods=['GET'])
@jwt_required()
def get_donor_profile(donor_id):
    try:
        user = mongo.db.users.find_one({'_id': ObjectId(donor_id)}, {'password': 0})
        if not user:
            return jsonify({'error': 'Donor not found'}), 404

        donations = list(mongo.db.donations.find({'donorId': ObjectId(donor_id), 'status': 'confirmed'}))
        ratings = [r['value'] for d in donations for r in d.get('ratings', [])]
        avg_rating = round(sum(ratings) / len(ratings), 1) if ratings else None

        recent_donations = [{
            'description': d.get('description'),
            'image': d.get('image'),
            'averageRating': round(
                sum(r['value'] for r in d.get('ratings', [])) / len(d['ratings']), 1
            ) if d.get('ratings') else None
        } for d in donations[:5]]

        return jsonify({
            'donor': {
                'name': user.get('name'),
                'email': user.get('email'),
                'profilePic': user.get('profilePic', '')
            },
            'averageRating': avg_rating,
            'recentDonations': recent_donations
        }), 200
    except Exception as e:
        return jsonify({'error': 'Internal Server Error', 'details': str(e)}), 500

# ✅ Get Confirmed Donations of a Donor
@donation_bp.route('/donor/<string:donor_id>/completed', methods=['GET'])
@jwt_required()
def get_donor_completed_donations(donor_id):
    donations = list(mongo.db.donations.find({'donorId': ObjectId(donor_id), 'status': 'confirmed'}))
    return jsonify([serialize_document(d) for d in donations])

# ✅ Get Donations by User
@donation_bp.route('/user/<string:user_id>', methods=['GET'])
@jwt_required()
def get_donations_by_user(user_id):
    donations = list(mongo.db.donations.find({'donorId': ObjectId(user_id), 'status': 'delivered'}))
    return jsonify([serialize_document(d) for d in donations])

# ✅ Get Donation Summary
@donation_bp.route('/<string:donation_id>/summary', methods=['GET'])
@jwt_required()
def get_donation_summary(donation_id):
    try:
        donation = mongo.db.donations.find_one({'_id': ObjectId(donation_id)})
        if not donation:
            return jsonify({'error': 'Donation not found'}), 404
        return jsonify(serialize_document(donation)), 200
    except Exception as e:
        return jsonify({'error': 'Internal Server Error', 'details': str(e)}), 500
