#!/bin/bash
set -e

BACKUP_FILE="/tmp/eks-backup-$(date +%Y%m%d-%H%M%S).yaml"

aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
kubectl get all --all-namespaces -o yaml > "$BACKUP_FILE"
aws s3 cp "$BACKUP_FILE" s3://$BUCKET_NAME/
