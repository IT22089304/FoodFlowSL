from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from bson import ObjectId
from datetime import datetime
from app.utils.db import mongo

order_bp = Blueprint('order', __name__)

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

#volanteer claims order
@order_bp.route('/volunteer/claim/<string:donation_id>', methods=['PUT'])
@jwt_required()
def claim_delivery(donation_id):
    try:
        user_id = get_jwt_identity()
        print(f"📢 Volunteer ID {user_id} attempting to claim delivery for Donation ID: {donation_id}")

        order = mongo.db.orders.find_one({'donationId': ObjectId(donation_id)})
        if not order:
            return jsonify({'error': 'Order not found for the specified donation ID'}), 404

        if order.get('status') != 'claimed':
            return jsonify({'error': 'This donation is not available for delivery'}), 400

        mongo.db.orders.update_one(
            {'_id': order['_id']},
            {'$set': {'volunteerId': ObjectId(user_id), 'status': 'in-transit'}}
        )

        print(f"✅ Delivery claimed successfully by Volunteer ID: {user_id}")
        return jsonify({'message': 'Delivery claimed successfully'}), 200

    except Exception as e:
        print(f"❌ Error in claim_delivery: {e}")
        return jsonify({'error': 'Failed to claim delivery', 'details': str(e)}), 500

# ✅ Create Order (Receiver claims a donation)
@order_bp.route('', methods=['POST'])
@jwt_required()
def create_order():
    user_id = get_jwt_identity()
    print(f"📢 Creating order by User ID: {user_id}")
    data = request.get_json()

    donation = mongo.db.donations.find_one({'_id': ObjectId(data['donationId'])})
    if not donation or donation.get('status') != 'pending':
        return jsonify({'error': 'Donation is not available for claim'}), 400

    mongo.db.donations.update_one(
        {'_id': ObjectId(data['donationId'])},
        {'$set': {'status': 'claimed', 'claimedBy': ObjectId(user_id), 'claimedAt': datetime.utcnow()}}
    )

    order = {
        'donationId': ObjectId(data['donationId']),
        'receiverId': ObjectId(user_id),
        'status': 'claimed',
        'claimedAt': datetime.utcnow(),
        'createdAt': datetime.utcnow()
    }
    mongo.db.orders.insert_one(order)
    return jsonify({'message': 'Order created successfully'}), 201

# ✅ Mark Order as Delivered
@order_bp.route('/<string:order_id>/mark-delivered', methods=['PUT'])
def mark_delivered(order_id):
    result = mongo.db.orders.update_one(
        {'_id': ObjectId(order_id)},
        {'$set': {'status': 'delivered', 'deliveredAt': datetime.utcnow()}}
    )

    if result.modified_count == 1:
        return jsonify({'message': 'Order marked as delivered'}), 200
    return jsonify({'error': 'Order not found or already delivered'}), 400

# ✅ Get My Orders (Receiver)
@order_bp.route('/my', methods=['GET'])
@jwt_required()
def get_my_orders():
    try:
        user_id = get_jwt_identity()
        print(f"📢 Fetching orders for User ID: {user_id}")

        orders = list(mongo.db.orders.find({'receiverId': ObjectId(user_id)}))
        for o in orders:
            donation = mongo.db.donations.find_one({'_id': ObjectId(o['donationId'])})
            if donation:
                o['donationId'] = serialize_document(donation)

        serialized_orders = [serialize_document(o) for o in orders]
        print(f"✅ Serialized Orders: {serialized_orders}")

        return jsonify(serialized_orders), 200

    except Exception as e:
        print(f"🔥 ERROR in /my orders route: {e}")
        return jsonify({'error': 'Internal Server Error', 'details': str(e)}), 500

# ✅ Get Assigned Orders (Volunteer)
@order_bp.route('/available', methods=['GET'])
@jwt_required()
def get_available_orders():
    try:
        orders = list(mongo.db.orders.find({'status': 'claimed', 'volunteerId': {'$exists': False}}))
        for o in orders:
            donation = mongo.db.donations.find_one({'_id': ObjectId(o['donationId'])})
            if donation:
                o['donationId'] = serialize_document(donation)

        return jsonify([serialize_document(o) for o in orders]), 200
    except Exception as e:
        print(f"🔥 ERROR in /available orders: {e}")
        return jsonify({'error': 'Internal Server Error', 'details': str(e)}), 500

# ✅ Volunteer Claims Delivery
@order_bp.route('/assigned', methods=['GET'])
@jwt_required()
def get_assigned_orders():
    try:
        user_id = get_jwt_identity()
        print(f"📢 Fetching assigned orders for Volunteer ID: {user_id}")

        orders = list(mongo.db.orders.find({'volunteerId': ObjectId(user_id)}))
        for o in orders:
            donation = mongo.db.donations.find_one({'_id': ObjectId(o['donationId'])})
            if donation:
                o['donationId'] = serialize_document(donation)

        return jsonify([serialize_document(o) for o in orders]), 200
    except Exception as e:
        print(f"🔥 ERROR in /assigned orders: {e}")
        return jsonify({'error': 'Internal Server Error', 'details': str(e)}), 500

# ✅ Update Order Status
@order_bp.route('/<string:order_id>/status', methods=['PUT'])
def update_order_status(order_id):
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

# ✅ Get Donor and Receiver Locations by Order ID
@order_bp.route('/locations/<string:order_id>', methods=['GET'])
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

# ✅ Get Donor and Receiver Details
@order_bp.route('/users/<string:order_id>', methods=['GET'])
@jwt_required()
def get_order_users(order_id):
    try:
        user_id = get_jwt_identity()
        print(f"📢 Fetching user details for Order ID: {order_id} by User ID: {user_id}")

        order = mongo.db.orders.find_one({'_id': ObjectId(order_id)})
        if not order:
            return jsonify({'error': 'Order not found'}), 404

        donation = mongo.db.donations.find_one({'_id': order.get('donationId')})
        if not donation:
            return jsonify({'error': 'Donation not found'}), 404

        donor = mongo.db.users.find_one({'_id': donation.get('donorId')}, {'password': 0})
        receiver = mongo.db.users.find_one({'_id': order.get('receiverId')}, {'password': 0})

        if not donor or not receiver:
            return jsonify({'error': 'Donor or receiver not found'}), 404

        donor = serialize_document(donor)
        receiver = serialize_document(receiver)

        print(f"✅ Donor: {donor}")
        print(f"✅ Receiver: {receiver}")

        return jsonify({'donor': donor, 'receiver': receiver}), 200

    except Exception as e:
        print(f"❌ Error fetching order users: {e}")
        return jsonify({'error': 'Failed to fetch user details', 'details': str(e)}), 500
