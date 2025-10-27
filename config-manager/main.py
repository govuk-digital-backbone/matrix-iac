import json
import os
import shutil
import subprocess

LOCAL_HS_CONFIG_FILE = "./homeserver.yaml"
HS_DATA_DIRECTORY = os.getenv('HS_DATA_DIRECTORY', '/mnt/data')
HS_CONFIG_UID = os.getenv('HS_CONFIG_UID', '991')
HS_CONFIG_GID = os.getenv('HS_CONFIG_GID', '991')

LOCAL_WEB_CONFIG_FILE = "./config.json"
WEB_CONFIG_DIRECTORY = os.getenv('WEB_CONFIG_DIRECTORY', '/mnt/web')

DO_HS = os.getenv('DO_HS', 'false').lower()[0] in ['t', '1']
DO_WEB = os.getenv('DO_WEB', 'false').lower()[0] in ['t', '1']


def print_tree(path):
    result = subprocess.run(["ls", "-lahR", path], capture_output=True, text=True)
    print(result.stdout)


def hs_config_file_exists():
    return os.path.isfile(LOCAL_HS_CONFIG_FILE)


def web_config_file_exists():
    return os.path.isfile(LOCAL_WEB_CONFIG_FILE)


def check_hs_data_directory():
    return os.path.isdir(HS_DATA_DIRECTORY)


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


def _handler(event, context):
    if not hs_config_file_exists():
        return {
            "statusCode": 404,
            "body": json.dumps({"error": "Homeserver YAML configuration file not found"})
        }

    if not web_config_file_exists():
        return {
            "statusCode": 404,
            "body": json.dumps({"error": "Element Web JSON configuration file not found"})
        }

    if event.get("print_efs_dir", False):
        if DO_HS:
            print(f"Synapse Homeserver Directory: {HS_DATA_DIRECTORY}")
            print_tree(HS_DATA_DIRECTORY)
            
        if DO_WEB:
            print(f"Element Web Config Directory: {WEB_CONFIG_DIRECTORY}")
            print_tree(WEB_CONFIG_DIRECTORY)

        return {
            "statusCode": 200,
            "body": json.dumps({"message": f"Printed files from EFS"})
        }

    copysuccess = False

    if DO_HS:
        if not check_hs_data_directory():
            return {
                "statusCode": 404,
                "body": json.dumps({"error": "Data directory not found"})
            }

        if not set_hs_directory_permissions():
            return {
                "statusCode": 500,
                "body": json.dumps({"error": "Failed to set directory permissions"})
            }

        copysuccess = copy_hs_config_file()

    if DO_WEB:
        copysuccess = copy_web_config_file()

    if copysuccess:
        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Configuration files copied successfully"})
        }

    return {
        "statusCode": 500,
        "body": json.dumps({"error": "Failed to copy one or more configuration files"})
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
