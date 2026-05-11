import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL', 'postgresql://postgres:POSTGRES_PASSWORD@localhost:55432/postgres')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    DEFAULT_PAGE_SIZE = 10
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret')

