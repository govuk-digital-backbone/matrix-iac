import os
import psycopg2

host = os.getenv("DB_HOST")
port = os.getenv("DB_PORT", "5432")
admin_user = os.getenv("DB_ADMIN_USER")
admin_pass = os.getenv("DB_ADMIN_PASS")

def init_database(database, user, password, with_encoding=False, with_public=False):
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
        
        created = False

        # Check if database already exists
        cur.execute("SELECT 1 FROM pg_database WHERE datname = %s;", (database,))
        if cur.fetchone():
            print(f"Database '{database}' already exists, skipping creation.")
        else:
            # Create the database with required locale and encoding
            create_sql = f"CREATE DATABASE {database}; "
            if with_encoding:
                create_sql += f"WITH ENCODING 'UTF8' "
                create_sql += f"LC_COLLATE='C' LC_CTYPE='C' "
                create_sql += f"TEMPLATE=template0 "
            #create_sql += f"OWNER={user};"
            cur.execute(create_sql)
            created = True
            print(f"Database '{database}' created successfully.")

        # Check if user already exists
        cur.execute("SELECT 1 FROM pg_roles WHERE rolname = %s;", (user,))
        if not cur.fetchone():
            # Create user if it does not exist
            create_user_sql = f"CREATE USER {user} WITH CREATEDB PASSWORD %s;"
            cur.execute(create_user_sql, (password,))
            print(f"User '{user}' created successfully.")
        else:
            print(f"User '{user}' already exists, skipping creation.")

        # Grant all privileges on the database to the user
        grant_sql = f"GRANT ALL PRIVILEGES ON DATABASE {database} TO {user};"
        cur.execute(grant_sql)
        print(f"Granted all privileges on database '{database}' to user '{user}'.")

        if with_public:
            for sql in [
                # Full access to the schema
                f"GRANT ALL ON SCHEMA public TO {user};",
                # Full access to all existing tables
                f"GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO {user};",
                # Full access to all existing sequences (needed for inserts with serial IDs)
                f"GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO {user};",
                # Make sure new tables and sequences will be accessible
                f"ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO {user};",
                f"ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO {user};"
            ]:
                cur.execute(sql)

            print(f"Granted ALL privileges on schema 'public' to user '{user}'.")

        return {"status": "created" if created else "updated"}

    except Exception as e:
        print(f"Error creating database: {e}")
        return {"status": "error", "error": str(e)}

    finally:
        if conn:
            conn.close()


def lambda_handler(event, context):
    synapse_db = os.getenv("SYNAPSE_DB", "synapse")
    synapse_user = os.getenv("SYNAPSE_USER", "synapse")
    synapse_pass = os.getenv("SYNAPSE_PASS")
    synapse_result = init_database(synapse_db, synapse_user, synapse_pass, with_encoding=True, with_public=False)

    mas_db = os.getenv("MAS_DB", "masdb")
    mas_user = os.getenv("MAS_USER", "mas_user")
    mas_pass = os.getenv("MAS_PASS")
    mas_result = init_database(mas_db, mas_user, mas_pass, with_encoding=False, with_public=True)

    return {
        "synapse": synapse_result,
        "mas": mas_result
    }
