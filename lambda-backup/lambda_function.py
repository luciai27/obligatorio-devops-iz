import os
import subprocess
import datetime
import boto3

def lambda_handler(event, context):
    try:
        region = os.environ["REGION"]
        cluster_name = os.environ["CLUSTER_NAME"]
        bucket_name = os.environ["BUCKET_NAME"]

        timestamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        backup_file = f"/tmp/eks-backup-{timestamp}.yaml"

        kubeconfig_file = "/tmp/kubeconfig"  #nuevo

        print("🔹 Starting EKS backup")
        print(f"🔹 Region: {region}")
        print(f"🔹 Cluster: {cluster_name}")
        print(f"🔹 Bucket: {bucket_name}")

        # Actualizar kubeconfig
        subprocess.run([
            "aws", "eks", "update-kubeconfig",
            "--region", region,
            "--name", cluster_name,
            "--kubeconfig", kubeconfig_file  #nuevo
        ], check=True)

        # Exportar recursos Kubernetes
        with open(backup_file, "w") as f:
            subprocess.run(
                #["kubectl", "get", "all", "--all-namespaces", "-o", "yaml"],
                ["kubectl", "--kubeconfig", kubeconfig_file, "get", "all", "--all-namespaces", "-o", "yaml"], #cambio
                stdout=f,
                check=True
            )

        # Subir a S3
        s3_client = boto3.client("s3", region_name=region)
        s3_client.upload_file(backup_file, bucket_name, os.path.basename(backup_file))

        print(f"✅ Backup uploaded to s3://{bucket_name}/{os.path.basename(backup_file)}")
        return {"status": "success", "file": backup_file}

    except Exception as e:
        print(f"❌ Error: {e}")
        raise
