import json
import os
import shutil
import subprocess
from pathlib import Path

LOCAL_HS_CONFIG_FILE = "./homeserver.yaml"
HS_DATA_DIRECTORY = os.getenv('HS_DATA_DIRECTORY', '/mnt/data')
HS_CONFIG_UID = os.getenv('HS_CONFIG_UID', '991')
HS_CONFIG_GID = os.getenv('HS_CONFIG_GID', '991')

LOCAL_WEB_CONFIG_FILE = "./web-config.json"
WEB_CONFIG_DIRECTORY = os.getenv('WEB_CONFIG_DIRECTORY', '/mnt/web')

LOCAL_MAS_CONFIG_FILE = "./mas-config.yaml"
MAS_CONFIG_DIRECTORY = os.getenv('MAS_CONFIG_DIRECTORY', '/mnt/mas')


def print_tree(path):
    result = subprocess.run(["ls", "-lahR", path], capture_output=True, text=True)
    print(result.stdout)


def file_exists(file):
    return os.path.isfile(file)


def check_directory(directory):
    return os.path.isdir(directory)


def set_hs_directory_permissions():
    try:
        os.chown(HS_DATA_DIRECTORY, int(HS_CONFIG_UID), int(HS_CONFIG_GID))
        return True
    except Exception as e:
        print(f"Error setting ownership of data directory: {e}")
    return False


def copy_hs_config_file():
    status = False
    destination = os.path.join(HS_DATA_DIRECTORY, 'homeserver.yaml')
    try:
        shutil.copyfile(LOCAL_HS_CONFIG_FILE, destination)
        status = True
    except Exception as e:
        print(f"Error copying configuration file: {e}")
        status = False

    if status == True:
        try:
            os.chown(destination, int(HS_CONFIG_UID), int(HS_CONFIG_GID))
        except Exception as e:
            print(f"Error setting ownership of configuration file: {e}")
            status = False

    return status


def copy_web_config_file():
    status = False
    destination = os.path.join(WEB_CONFIG_DIRECTORY, 'config.json')
    try:
        shutil.copyfile(LOCAL_WEB_CONFIG_FILE, destination)
        status = True
    except Exception as e:
        print(f"Error copying configuration file: {e}")
        status = False

    return status


def copy_mas_config_file():
    status = False
    destination = os.path.join(MAS_CONFIG_DIRECTORY, 'config.yaml')
    try:
        shutil.copyfile(LOCAL_MAS_CONFIG_FILE, destination)
        status = True
    except Exception as e:
        print(f"Error copying configuration file: {e}")
        status = False

    if status == True:
        hs_dest = os.path.join(MAS_CONFIG_DIRECTORY, 'homeserver.yaml')
        try:
            shutil.copyfile(LOCAL_HS_CONFIG_FILE, hs_dest)
            status = True
        except Exception as e:
            print(f"Error copying configuration file: {e}")
            status = False

    return status


def return_printed():
    return {
        "statusCode": 200,
        "body": json.dumps({"message": f"Printed files from EFS"})
    }


def _handler(event, context):
    action = event.get("action", "empty") # empty | homeserver | web | mas
    print_efs_dir = event.get("print_efs_dir", False)

    if action == "empty":
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "No action specified"})
        }

    if action == "homeserver":
        if not file_exists(LOCAL_HS_CONFIG_FILE):
            return {
                "statusCode": 404,
                "body": json.dumps({"error": "Homeserver YAML configuration file not found"})
            }

        if not check_directory(HS_DATA_DIRECTORY):
            return {
                "statusCode": 404,
                "body": json.dumps({"error": "Data directory not found"})
            }

        if print_efs_dir:
            print(f"Synapse Homeserver Directory: {HS_DATA_DIRECTORY}")
            print_tree(HS_DATA_DIRECTORY)
            return return_printed()

        if not set_hs_directory_permissions():
            return {
                "statusCode": 500,
                "body": json.dumps({"error": "Failed to set directory permissions"})
            }

        if copy_hs_config_file():
            return {
                "statusCode": 200,
                "body": json.dumps({"message": "Homeserver configuration file copied successfully"})
            }

        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Failed to copy homeserver configuration file"})
        }

    if action == "web":
        if not file_exists(LOCAL_WEB_CONFIG_FILE):
            return {
                "statusCode": 404,
                "body": json.dumps({"error": "Element Web JSON configuration file not found"})
            }

        if not check_directory(WEB_CONFIG_DIRECTORY):
            return {
                "statusCode": 404,
                "body": json.dumps({"error": "Element Web config directory not found"})
            }

        if print_efs_dir:
            print(f"Element Web config Directory: {WEB_CONFIG_DIRECTORY}")
            print_tree(WEB_CONFIG_DIRECTORY)
            return return_printed()

        if copy_web_config_file():
            return {
                "statusCode": 200,
                "body": json.dumps({"message": "Element Web configuration file copied successfully"})
            }

        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Failed to copy Element Web configuration file"})
        }

    if action == "mas":
        if not file_exists(LOCAL_MAS_CONFIG_FILE):
            return {
                "statusCode": 404,
                "body": json.dumps({"error": "MAS YAML configuration file not found"})
            }

        if not file_exists(LOCAL_HS_CONFIG_FILE):
            return {
                "statusCode": 404,
                "body": json.dumps({"error": "Homeserver YAML configuration file not found"})
            }

        if not check_directory(MAS_CONFIG_DIRECTORY):
            return {
                "statusCode": 404,
                "body": json.dumps({"error": "MAS config directory not found"})
            }

        if print_efs_dir:
            print(f"MAS config Directory: {MAS_CONFIG_DIRECTORY}")
            print_tree(MAS_CONFIG_DIRECTORY)
            return return_printed()
        
        key_rsa_001 = os.path.join(MAS_CONFIG_DIRECTORY, 'key_rsa_001.pem')
        if not file_exists(key_rsa_001):
            # generate a private RSA key and write the key_rsa_001.pem file
            out_path = Path(key_rsa_001)
            cmd = ["openssl", "genrsa", "2048"]

            with open(out_path, "w") as f:
                subprocess.run(cmd, check=True, stdout=f)

        key_ec_001 = os.path.join(MAS_CONFIG_DIRECTORY, 'key_ec_001.pem')
        if not file_exists(key_ec_001):
            # generate a private EC key and write the key_ec_001.pem file
            out_path = Path(key_ec_001)
            cmd = ["openssl", "genpkey", "-algorithm", "EC", "-pkeyopt", "ec_paramgen_curve:prime256v1"]

            with open(out_path, "w") as f:
                subprocess.run(cmd, check=True, stdout=f)

        if copy_mas_config_file():
            return {
                "statusCode": 200,
                "body": json.dumps({"message": "MAS configuration file copied successfully"})
            }

        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Failed to copy MAS configuration file"})
        }

    return {
        "statusCode": 500,
        "body": json.dumps({"error": "Failed to process action"})
    }


def lambda_handler(event, context):
    result = _handler(event, context)
    print(
        json.dumps(
            {
                "event": event,
                "context": context,
                "result": result
            }, 
            default=str
        )
    )
    return result
