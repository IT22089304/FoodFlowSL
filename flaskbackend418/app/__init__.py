from flask import Flask
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from .routes.auth import auth_bp
from .routes.donations import donation_bp
from .routes.orders import order_bp
from .routes.notifications import notification_bp
from .routes.feedback import feedback_bp
from .utils.db import init_db
from app.jobs.donation_jobs import start_scheduler
jwt = JWTManager()  # <-- ADD THIS

def create_app():
    app = Flask(__name__)
    CORS(app)
    start_scheduler()  # ✅ Start the job once

    # 🔐 Add this JWT config
    app.config['JWT_SECRET_KEY'] = 'somethingSuperSecretAndRandom123'  # change this in prod

    # ✅ Init DB & JWT
    init_db(app)
    jwt.init_app(app)  # <-- ADD THIS

    # Blueprints
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(donation_bp, url_prefix='/api/donations')
    app.register_blueprint(order_bp, url_prefix='/api/orders')
    app.register_blueprint(notification_bp, url_prefix='/api/notifications')
    app.register_blueprint(feedback_bp, url_prefix='/api/feedback')
    return app
