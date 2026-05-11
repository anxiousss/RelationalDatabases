from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from .config import Config
from flasgger import Swagger


db = SQLAlchemy()
migrate = Migrate()

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    swagger = Swagger(app)

    from .models import user, dicts, words

    db.init_app(app)
    migrate.init_app(app, db)

    from .api.routes import register_all_routes

    register_error_handlers(app)
    register_all_routes(app)

    return app


def register_error_handlers(app):
    from .utils.errors import handle_404, handle_generic
    app.register_error_handler(404, handle_404)
    app.register_error_handler(Exception, handle_generic)