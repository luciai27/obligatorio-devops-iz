#!/bin/bash
set -e

#BACKUP_FILE="/tmp/eks-backup-$(date +%Y%m%d-%H%M%S).yaml"

#aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
#kubectl get all --all-namespaces -o yaml > "$BACKUP_FILE"
#aws s3 cp "$BACKUP_FILE" s3://$BUCKET_NAME/



#set -e

echo "🔹 Starting EKS backup at $(date)"
echo "🔹 Region: $REGION"
echo "🔹 Cluster: $CLUSTER_NAME"
echo "🔹 Bucket: $BUCKET_NAME"

BACKUP_FILE="/tmp/eks-backup-$(date +%Y%m%d-%H%M%S).yaml"

# Configura kubeconfig
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"

# Exportar recursos
kubectl get all --all-namespaces -o yaml > "$BACKUP_FILE"

# Subir a S3
aws s3 cp "$BACKUP_FILE" "s3://$BUCKET_NAME/"

echo "✅ Backup uploaded to s3://$BUCKET_NAME/"