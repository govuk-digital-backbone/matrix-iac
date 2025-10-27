import os
import psycopg2

def lambda_handler(event, context):
    host = os.environ["DB_HOST"]
    port = os.getenv("DB_PORT", "5432")
    admin_user = os.environ["DB_ADMIN_USER"]
    admin_pass = os.environ["DB_ADMIN_PASS"]
    synapse_db = os.getenv("SYNAPSE_DB", "synapse")

    conn = None
    try:
        conn = psycopg2.connect(
            dbname="postgres",
            user=admin_user,
            password=admin_pass,
            host=host,
            port=port,
        )
        conn.autocommit = True
        cur = conn.cursor()

        # Check if database already exists
        cur.execute("SELECT 1 FROM pg_database WHERE datname = %s;", (synapse_db,))
        if cur.fetchone():
            print(f"Database '{synapse_db}' already exists, skipping creation.")
            return {"status": "exists"}

        # Create the database with required locale and encoding
        create_sql = (
            f"CREATE DATABASE {synapse_db} "
            f"WITH ENCODING 'UTF8' "
            f"LC_COLLATE='C' LC_CTYPE='C' "
            f"TEMPLATE=template0 "
            f"OWNER={admin_user};"
        )
        cur.execute(create_sql)
        print(f"Database '{synapse_db}' created successfully.")
        return {"status": "created"}

    except Exception as e:
        print(f"Error creating database: {e}")
        return {"status": "error", "error": str(e)}

    finally:
        if conn:
            conn.close()
