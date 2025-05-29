import os
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

jwt = JWTManager()

def create_app():
    print("📢 Starting create_app()...")
    app = Flask(__name__)
    CORS(app)
    print("✅ Flask initialized!")

    # ✅ Start Background Scheduler
    try:
        start_scheduler()
        print("✅ Scheduler started!")
    except Exception as e:
        print(f"❌ Error starting scheduler: {e}")

    # ✅ JWT Configuration with Environment Variable
    jwt_secret = os.getenv('JWT_SECRET_KEY', 'MyUltraStrongSecretKey_2025_FoodFlowSL!')

    app.config['JWT_SECRET_KEY'] = jwt_secret
    print(f"🚀 Loaded JWT_SECRET_KEY: {app.config['JWT_SECRET_KEY']}")

    if jwt_secret == 'superSecretFallbackKey123':
        print("⚠️  WARNING: Using fallback JWT secret key. "
              "Set 'JWT_SECRET_KEY' as an environment variable for production security!")
    else:
        print("🔐 JWT Secret Key Loaded: True")

    # ✅ Initialize Database
    try:
        init_db(app)
        print("✅ Database initialized!")
    except Exception as e:
        print(f"❌ Error initializing DB: {e}")

    # ✅ Initialize JWT
    jwt.init_app(app)
    print("✅ JWT initialized!")

    # ✅ Register Blueprints
    try:
        app.register_blueprint(auth_bp, url_prefix='/api/auth')
        app.register_blueprint(donation_bp, url_prefix='/api/donations')
        app.register_blueprint(order_bp, url_prefix='/api/orders')
        app.register_blueprint(notification_bp, url_prefix='/api/notifications')
        app.register_blueprint(feedback_bp, url_prefix='/api/feedback')
        print("✅ Blueprints registered!")
    except Exception as e:
        print(f"❌ Error registering blueprints: {e}")

    print("🎉 App creation completed successfully!")
    return app