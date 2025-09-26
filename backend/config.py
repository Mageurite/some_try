import os

basedir = os.path.abspath(os.path.dirname(__file__))

class Config:
    """Application configuration settings."""

    # ===== Basic settings =====
    SECRET_KEY = 'super-secret-key'  # Flask secret key (should be changed in production)
    SQLALCHEMY_DATABASE_URI = f"sqlite:///{os.path.join(basedir, 'db', 'users.db')}"  # SQLite DB path
    SQLALCHEMY_TRACK_MODIFICATIONS = False  # Disable modification tracking to save resources

    # ===== JWT settings =====
    JWT_SECRET_KEY = "your-jwt-secret"     # Secret key for signing JWTs
    JWT_ACCESS_TOKEN_EXPIRES = 18000       # Token expiry time (in seconds) - 5 hours
    JWT_COOKIE_CSRF_PROTECT = False        # Disable CSRF protection for JWT cookies

    REDIS_TOKEN_TTL_SECONDS = 18000        # TTL for storing JWT token in Redis (in seconds)

    # ===== Email settings =====
    MAIL_SERVER = 'your email server'      # SMTP server address
    MAIL_PORT = 587                         # SMTP port (587 for TLS)
    MAIL_USE_TLS = True                     # Use TLS for email sending
    MAIL_USERNAME = "your email username"   # SMTP account username
    MAIL_PASSWORD = "your password"         # SMTP account password
    MAIL_DEFAULT_SENDER = ("TutorNet", "your email")  # Default sender name and email
