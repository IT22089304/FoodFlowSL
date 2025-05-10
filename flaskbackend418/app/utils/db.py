from flask_pymongo import PyMongo

mongo = PyMongo()

def init_db(app):
    app.config['MONGO_URI'] = 'mongodb+srv://lahiruflutter:lahiru@cluster0.oxqke.mongodb.net/flutter414?retryWrites=true&w=majority&appName=Cluster0'
    mongo.init_app(app)