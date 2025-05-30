#!/bin/bash
set -e

AWS_REGION="us-east-1"  # Cambia esto
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_BASE_URL="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

SERVICES=("vote" "result" "worker")

BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
COMMIT_HASH=$(git rev-parse --short HEAD)

case "$BRANCH_NAME" in
  dev)
    BRANCH_TAG="dev"
    ;;
  test)
    BRANCH_TAG="test"
    ;;
  main | master)
    BRANCH_TAG="prod"
    ;;
  *)
    echo "❌ Rama '$BRANCH_NAME' no válida para tagging. Usá solo 'dev', 'test', o 'main'."
    exit 1
    ;;
esac

echo "🌿 Rama: $BRANCH_NAME"
echo "🔖 Tag rama: $BRANCH_TAG"
echo "🔨 Commit: $COMMIT_HASH"

echo "🔐 Login ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin "$ECR_BASE_URL"

for SERVICE in "${SERVICES[@]}"; do
  LOCAL_IMAGE="voting-app/$SERVICE"
  ECR_REPO="voting-app/$SERVICE"
  ECR_REPO_URL="$ECR_BASE_URL/$ECR_REPO"

  echo "📦 Construyendo imagen $SERVICE..."
  docker build -t "$LOCAL_IMAGE:latest" "./$SERVICE"

  if ! aws ecr describe-repositories --repository-names "$ECR_REPO" --region $AWS_REGION > /dev/null 2>&1; then
    echo "🚀 Creando repositorio $ECR_REPO..."
    aws ecr create-repository --repository-name "$ECR_REPO" --region $AWS_REGION
  else
    echo "✅ Repositorio $ECR_REPO existe."
  fi

  # Tags
  TAGS=("$BRANCH_TAG" "$COMMIT_HASH")
  if [[ "$BRANCH_TAG" == "prod" ]]; then
    TAGS+=("latest")
  fi

  for TAG in "${TAGS[@]}"; do
    FULL_TAG="$ECR_REPO_URL:$TAG"
    echo "🏷️ Etiquetando $SERVICE como $TAG"
    docker tag "$LOCAL_IMAGE:latest" "$FULL_TAG"
    echo "📤 Subiendo $SERVICE:$TAG"
    docker push "$FULL_TAG"
  done

  echo "✅ $SERVICE: imágenes subidas con tags: ${TAGS[*]}"
  echo "-------------------------------------"
done

echo "🏁 Proceso terminado."