import os
import boto3
import subprocess
from datetime import datetime

def lambda_handler(event, context):
    region = os.environ.get("REGION")
    cluster_name = os.environ.get("CLUSTER_NAME")
    bucket_name = os.environ.get("BUCKET_NAME")

    timestamp = datetime.utcnow().strftime("%Y%m%d-%H%M%S")
    backup_file = f"/tmp/eks-backup-{timestamp}.yaml"

    try:
        # Configurar kubeconfig del cluster
        print("Actualizando kubeconfig para el cluster...")
        subprocess.check_call([
            "aws", "eks", "update-kubeconfig",
            "--region", region,
            "--name", cluster_name
        ])

        # Ejecutar el backup
        print("Ejecutando backup con kubectl...")
        with open(backup_file, "w") as f:
            subprocess.check_call(
                ["kubectl", "get", "all", "--all-namespaces", "-o", "yaml"],
                stdout=f
            )

        # Subir a S3
        print("Subiendo backup a S3...")
        s3 = boto3.client("s3")
        s3.upload_file(backup_file, bucket_name, f"eks-backups/{os.path.basename(backup_file)}")

        return {
            "statusCode": 200,
            "body": f"Backup subido a s3://{bucket_name}/eks-backups/{os.path.basename(backup_file)}"
        }

    except subprocess.CalledProcessError as e:
        print(f"Error ejecutando comando: {e}")
        return {
            "statusCode": 500,
            "body": f"Fallo al ejecutar comando: {e}"
        }

    except Exception as ex:
        print(f"Error general: {ex}")
        return {
            "statusCode": 500,
            "body": f"Error general: {ex}"
        }
