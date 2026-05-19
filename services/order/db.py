import psycopg2
import os

conn = psycopg2.connect(
    host=os.getenv("DB_HOST", "postgres"),
    database=os.getenv("DB_NAME", "microservices"),
    user=os.getenv("DB_USER", "postgres"),
    password=os.getenv("DB_PASSWORD", "postgres")
)

conn.autocommit = True