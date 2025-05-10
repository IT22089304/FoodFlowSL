from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from bson import ObjectId
from datetime import datetime, timedelta
from app.utils.db import mongo

donation_bp = Blueprint('donation', __name__)

from flask import request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime
from bson import ObjectId
from dateutil import parser  # ✅ Add this

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from bson import ObjectId
from datetime import datetime
from app.utils.db import mongo
from pytz import timezone
from math import radians, cos, sin, asin, sqrt
from app.utils.notification_service import create_notification
sri_lanka_tz = timezone('Asia/Colombo')
# Distance calculation helper (haversine formula)
def haversine(lon1, lat1, lon2, lat2):
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
    dlon = lon2 - lon1 
    dlat = lat2 - lat1 
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a)) 
    km = 6367 * c
    return km


# ✅ Get a single donation by ID
@donation_bp.route('/<string:donation_id>', methods=['GET'])
@jwt_required()
def get_donation(donation_id):
    try:
        donation = mongo.db.donations.find_one({'_id': ObjectId(donation_id)})
        if not donation:
            return jsonify({'error': 'Donation not found'}), 404

        # Convert ObjectId fields to string
        donation['_id'] = str(donation['_id'])
        if 'donorId' in donation:
            donation['donorId'] = str(donation['donorId'])
        if 'claimedBy' in donation:
            donation['claimedBy'] = str(donation['claimedBy'])
        if 'assignedVolunteerId' in donation:
            donation['assignedVolunteerId'] = str(donation['assignedVolunteerId'])

        return jsonify(donation), 200
    except Exception as e:
        print(f"Error fetching donation: {e}")
        return jsonify({'error': 'Invalid donation ID'}), 400
    
from dateutil.parser import parse as parse_date  # Make sure to install python-dateutil

@donation_bp.route('/', methods=['POST'])
@jwt_required()
def create_donation():
    user_id = get_jwt_identity()
    data = request.get_json()

    # Validate required fields
    if not all(k in data for k in ("description", "quantity", "location", "image", "expiresAt")):
        return jsonify({'error': 'Missing fields'}), 400

    try:
        # Parse the frontend-passed expiration date (ISO string preferred)
        expires_at = parse_date(data['expiresAt'])
    except Exception:
        return jsonify({'error': 'Invalid expiresAt format'}), 400

    # Save donation to database
    donation = {
        'donorId': ObjectId(user_id),
        'description': data['description'],
        'quantity': data['quantity'],
        'location': {
            'lat': data['location']['lat'],
            'lng': data['location']['lng']
        },
        'image': data['image'],
        'status': 'pending',
        'expiresAt': expires_at,
        'createdAt': datetime.now(sri_lanka_tz)  
            }
    mongo.db.donations.insert_one(donation)

    # ✅ Notify receivers within 20km
    pickup_lat = donation['location']['lat']
    pickup_lng = donation['location']['lng']

    receivers = mongo.db.users.find({'role': 'receiver'})
    for receiver in receivers:
        if 'location' in receiver:
            rec_lat = receiver['location'].get('lat')
            rec_lng = receiver['location'].get('lng')
            if rec_lat is not None and rec_lng is not None:
                distance = haversine(pickup_lng, pickup_lat, rec_lng, rec_lat)
                if distance <= 20:
                    create_notification(
                        user_id=receiver['_id'],
                        message="New food donation available near you!",
                        notif_type="donation",
                        donation=donation,
                        with_image=True
                    )

    return jsonify({'message': 'Donation created and nearby receivers notified!'}), 201

@donation_bp.route('/', methods=['GET'])
@jwt_required()
def get_all_donations():
    donations = list(mongo.db.donations.find({'status': 'pending'}))
    for d in donations:
        d['_id'] = str(d['_id'])
        d['donorId'] = str(d['donorId'])
    return jsonify(donations)

@donation_bp.route('/my', methods=['GET'])
@jwt_required()
def get_my_donations():
    user_id = get_jwt_identity()
    donations = list(mongo.db.donations.find({'donorId': ObjectId(user_id)}))
    for d in donations:
        d['_id'] = str(d['_id'])
        d['donorId'] = str(d['donorId'])
    return jsonify(donations)

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

@donation_bp.route('/expired', methods=['DELETE'])
@jwt_required()
def delete_expired_donations():
    now = datetime.utcnow()
    result = mongo.db.donations.delete_many({
        'status': 'pending',
        'expiresAt': {'$lt': now}
    })
    return jsonify({'message': f'{result.deleted_count} expired donations removed'})

@donation_bp.route('/<string:donation_id>', methods=['PUT'])
@jwt_required()

def update_donation(donation_id):
    user_id = get_jwt_identity()
    data = request.get_json()
    donation = mongo.db.donations.find_one({'_id': ObjectId(donation_id), 'donorId': ObjectId(user_id)})
    if not donation:
        return jsonify({'error': 'Donation not found or unauthorized'}), 404
    updates = {}
    if 'description' in data: updates['description'] = data['description']
    if 'quantity' in data: updates['quantity'] = data['quantity']
    if 'expiresAt' in data: updates['expiresAt'] = datetime.strptime(data['expiresAt'], '%Y-%m-%dT%H:%M:%S')
    if 'image' in data: updates['image'] = data['image']
    mongo.db.donations.update_one({'_id': ObjectId(donation_id)}, {'$set': updates})
    return jsonify({'message': 'Donation updated successfully'})

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

    if not (1 <= rating_value <= 5):
        return jsonify({'error': 'Rating must be between 1 and 5'}), 400

    donation = mongo.db.donations.find_one({'_id': ObjectId(donation_id)})
    if not donation:
        return jsonify({'error': 'Donation not found'}), 404

    existing_ratings = donation.get('ratings', [])
    has_already_rated = any(str(r['userId']) == user_id for r in existing_ratings)

    if has_already_rated:
        return jsonify({'error': 'You have already rated this donation'}), 403

    new_rating = {'userId': ObjectId(user_id), 'value': rating_value}
    mongo.db.donations.update_one(
        {'_id': ObjectId(donation_id)},
        {'$push': {'ratings': new_rating}}
    )

    return jsonify({'message': 'Rating submitted'}), 200

@donation_bp.route('/<string:donation_id>/my-rating', methods=['GET'])
@jwt_required()
def get_my_rating(donation_id):
    user_id = get_jwt_identity()

    donation = mongo.db.donations.find_one({'_id': ObjectId(donation_id)})
    if not donation:
        return jsonify({'error': 'Donation not found'}), 404

    ratings = donation.get('ratings', [])
    for r in ratings:
        if str(r['userId']) == user_id:
            return jsonify({'rating': r['value']}), 200

    return jsonify({'rating': None}), 200

@donation_bp.route('/donor/<string:donor_id>/profile', methods=['GET'])
@jwt_required()
def get_donor_profile(donor_id):
    try:
        # Fetch donor user info
        user = mongo.db.users.find_one({'_id': ObjectId(donor_id)}, {'password': 0})
        if not user:
            return jsonify({'error': 'Donor not found'}), 404

        # Fetch confirmed donations made by this donor
        donations = list(mongo.db.donations.find({
            'donorId': ObjectId(donor_id),
            'status': 'confirmed'
        }))

        # Calculate average rating
        ratings = [r['value'] for d in donations for r in d.get('ratings', [])]
        avg_rating = round(sum(ratings) / len(ratings), 1) if ratings else None

        # Limit to 5 recent confirmed donations
        recent_donations = [
            {
                'description': d.get('description'),
                'image': d.get('image'),
                'averageRating': (
                    round(sum(r['value'] for r in d.get('ratings', [])) / len(d['ratings']), 1)
                    if d.get('ratings') else None
                )
            }
            for d in donations[:5]
        ]

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
        print("Error fetching donor profile:", e)
        return jsonify({'error': 'Something went wrong'}), 500
    
@donation_bp.route('/donor/<string:donor_id>/completed', methods=['GET'])
@jwt_required()
def get_donor_completed_donations(donor_id):
    donations = list(mongo.db.donations.find({
        'donorId': ObjectId(donor_id),
        'status': 'confirmed'
    }))
    for d in donations:
        d['_id'] = str(d['_id'])
        d['donorId'] = str(d['donorId'])
    return jsonify(donations)

@donation_bp.route('/user/<string:user_id>', methods=['GET'])
@jwt_required()
def get_donations_by_user(user_id):
    donations = list(mongo.db.donations.find({
        'donorId': ObjectId(user_id),
        'status': 'delivered'  # Only completed donations
    }))
    for d in donations:
        d['_id'] = str(d['_id'])
        d['donorId'] = str(d['donorId'])
    return jsonify(donations), 200

@donation_bp.route('/<string:donation_id>/summary', methods=['GET'])
@jwt_required()
def get_donation_summary(donation_id):
    try:
        donation = mongo.db.donations.find_one({'_id': ObjectId(donation_id)})
        if not donation:
            return jsonify({'error': 'Donation not found'}), 404

        summary = {
            '_id': str(donation['_id']),
            'description': donation.get('description'),
            'quantity': donation.get('quantity'),
            'image': donation.get('image'),
            'expiresAt': donation.get('expiresAt').isoformat() if donation.get('expiresAt') else None,
            'createdAt': donation.get('createdAt').isoformat() if donation.get('createdAt') else None,
            'donorId': str(donation.get('donorId')) if donation.get('donorId') else None,
        }

        return jsonify(summary), 200
    except Exception as e:
        print(f"❌ Error fetching donation summary: {e}")
        return jsonify({'error': 'Internal Server Error'}), 500
