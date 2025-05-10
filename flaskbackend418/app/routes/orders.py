from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from bson import ObjectId
from datetime import datetime
from app.utils.db import mongo

order_bp = Blueprint('order', __name__)

# ✅ Receiver claims a donation (creates an order)
@order_bp.route('', methods=['POST'])
@jwt_required()
def create_order():
    user_id = get_jwt_identity()
    data = request.get_json()
    donation = mongo.db.donations.find_one({'_id': ObjectId(data['donationId'])})
    if not donation or donation.get('status') != 'pending':
        return jsonify({'error': 'Donation is not available for claim'}), 400

    # Update donation
    mongo.db.donations.update_one(
        {'_id': ObjectId(data['donationId'])},
        {'$set': {'status': 'claimed', 'claimedBy': ObjectId(user_id), 'claimedAt': datetime.utcnow()}}
    )

    # Create order
    order = {
        'donationId': ObjectId(data['donationId']),
        'receiverId': ObjectId(user_id),
        'status': 'claimed',
        'claimedAt': datetime.utcnow(),
        'createdAt': datetime.utcnow()
    }
    mongo.db.orders.insert_one(order)
    return jsonify({'message': 'Order created successfully'}), 201


# ✅ Mark an order as delivered
@order_bp.route('/<string:order_id>/mark-delivered', methods=['PUT'])
@jwt_required()
def mark_delivered(order_id):
    result = mongo.db.orders.update_one(
        {'_id': ObjectId(order_id)},
        {
            '$set': {
                'status': 'delivered',
                'deliveredAt': datetime.utcnow()
            }
        }
    )

    if result.modified_count == 1:
        return jsonify({'message': 'Order marked as delivered'}), 200
    else:
        return jsonify({'error': 'Order not found or already delivered'}), 400
    
# ✅ Get current user's (receiver's) orders
@order_bp.route('/my', methods=['GET'])
@jwt_required()
def get_my_orders():
    user_id = get_jwt_identity()
    orders = list(mongo.db.orders.find({'receiverId': ObjectId(user_id)}))

    for o in orders:
        o['_id'] = str(o['_id'])
        o['receiverId'] = str(o['receiverId'])
        o['status'] = o.get('status', 'claimed')

        # ✅ replace donationId with full object
        donation = mongo.db.donations.find_one({'_id': ObjectId(o['donationId'])})
        if donation:
            donation['_id'] = str(donation['_id'])
            o['donationId'] = donation  # 🔁 replace ID with object

        if 'volunteerId' in o:
            o['volunteerId'] = str(o['volunteerId'])

    return jsonify(orders)

# ✅ Get available orders (for volunteers)
@order_bp.route('/available', methods=['GET'])
@jwt_required()
def get_available_orders():
    orders = list(mongo.db.orders.find({
        'status': 'claimed',
        'volunteerId': {'$exists': False}
    }))

    for o in orders:
        o['_id'] = str(o['_id'])
        o['receiverId'] = str(o['receiverId'])

        # 🔁 Convert donationId string → full donation object
        donation = mongo.db.donations.find_one({'_id': ObjectId(o['donationId'])})
        if donation:
            donation['_id'] = str(donation['_id'])
            o['donationId'] = donation

    return jsonify(orders)
@order_bp.route('/assigned', methods=['GET'])
@jwt_required()
def get_assigned_orders():
    user_id = get_jwt_identity()
    orders = list(mongo.db.orders.find({'volunteerId': ObjectId(user_id)}))

    for o in orders:
        o['_id'] = str(o['_id'])
        o['receiverId'] = str(o['receiverId'])
        o['volunteerId'] = str(o['volunteerId'])
        o['status'] = o.get('status', 'in-transit')  # ✅ optional fallback

        # 🔁 Replace donationId with full object
        donation = mongo.db.donations.find_one({'_id': ObjectId(o['donationId'])})
        if donation:
            donation['_id'] = str(donation['_id'])
            o['donationId'] = donation

    return jsonify(orders)

# ✅ Volunteer claims delivery
@order_bp.route('/volunteer/claim/<string:donation_id>', methods=['PUT'])
@jwt_required()
def claim_delivery(donation_id):
    user_id = get_jwt_identity()
    order = mongo.db.orders.find_one({'donationId': ObjectId(donation_id)})
    if not order or order.get('status') != 'claimed':
        return jsonify({'error': 'This donation is not available for delivery'}), 400

    mongo.db.orders.update_one(
        {'_id': order['_id']},
        {'$set': {'volunteerId': ObjectId(user_id), 'status': 'in-transit'}}
    )
    return jsonify({'message': 'Delivery claimed successfully'})

# ✅ Volunteer or receiver updates status: in-transit, delivered, confirmed
@order_bp.route('/<string:order_id>/status', methods=['PUT'])
@jwt_required()
def update_order_status(order_id):
    user_id = get_jwt_identity()
    data = request.get_json()
    valid_statuses = ['in-transit', 'delivered', 'confirmed']

    if data.get('status') not in valid_statuses:
        return jsonify({'error': 'Invalid status update'}), 400

    order = mongo.db.orders.find_one({'_id': ObjectId(order_id)})
    if not order:
        return jsonify({'error': 'Order not found'}), 404

    update_data = {'status': data['status']}
    if data['status'] == 'delivered':
        update_data['deliveredAt'] = datetime.utcnow()
    if data['status'] == 'confirmed':
        mongo.db.donations.update_one({'_id': order['donationId']}, {'$set': {'status': 'confirmed'}})

    mongo.db.orders.update_one({'_id': ObjectId(order_id)}, {'$set': update_data})
    return jsonify({'message': 'Order status updated'})
# ✅ Get donor and receiver lat/lng by orderId
@order_bp.route('/locations/<string:order_id>', methods=['GET'])
@jwt_required()
def get_donor_receiver_locations(order_id):
    try:
        order = mongo.db.orders.find_one({'_id': ObjectId(order_id)})
        if not order:
            return jsonify({"error": "Order not found"}), 404

        donation = mongo.db.donations.find_one({'_id': order['donationId']})
        if not donation:
            return jsonify({"error": "Donation not found"}), 404

        donor = mongo.db.users.find_one({'_id': donation['donorId']})
        receiver = mongo.db.users.find_one({'_id': order['receiverId']})

        if not donor or not receiver:
            return jsonify({"error": "Donor or receiver not found"}), 404

        return jsonify({
            "donorLocation": donor.get('location', {}),
            "receiverLocation": receiver.get('location', {})
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@order_bp.route('/users/<order_id>', methods=['GET'])
def get_order_users(order_id):
    try:
        order = mongo.db.orders.find_one({'_id': ObjectId(order_id)})
        if not order:
            return jsonify({'error': 'Order not found'}), 404

        donation = mongo.db.donations.find_one({'_id': order['donationId']})
        if not donation:
            return jsonify({'error': 'Donation not found'}), 404

        donor = mongo.db.users.find_one({'_id': donation['donorId']}, {'password': 0})
        receiver = mongo.db.users.find_one({'_id': order['receiverId']}, {'password': 0})

        if not donor or not receiver:
            return jsonify({'error': 'User(s) not found'}), 404

        donor['_id'] = str(donor['_id'])
        receiver['_id'] = str(receiver['_id'])

        return jsonify({
            'donor': donor,
            'receiver': receiver
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500
