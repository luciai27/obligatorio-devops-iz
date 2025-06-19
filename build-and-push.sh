#!/bin/bash
set -e

AWS_REGION="us-east-1"  # Cambia esto si es necesario
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
    echo "❌ Rama '$BRANCH_NAME' no válida para tagging. Usá solo 'dev', 'staging' o 'main'."
    exit 1
    ;;
esac

TAG_COMBINADO="$BRANCH_TAG-$COMMIT_HASH"

echo "🌿 Rama: $BRANCH_NAME"
echo "🔖 Tag combinado: $TAG_COMBINADO"
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

  TAGS=("$TAG_COMBINADO")
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

# ----------------------------
# 🧱 Generar docker-compose.<env>.yml
# ----------------------------

COMPOSE_FILE="docker-compose.generated.${BRANCH_TAG}.yml"
#TAG="${BRANCH_TAG}-${COMMIT_HASH}"
TAG="latest"

echo "📝 Generando $COMPOSE_FILE con tag $TAG..."

cat > "$COMPOSE_FILE" <<EOF
version: "3.8"

services:
  vote:
    image: $ECR_BASE_URL/voting-app/vote:$TAG
    depends_on:
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 15s
      timeout: 5s
      retries: 3
      start_period: 10s
    ports:
      - "8080:80"
    networks:
      - front-tier
      - back-tier

  result:
    image: $ECR_BASE_URL/voting-app/result:$TAG
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "8081:80"
    networks:
      - front-tier
      - back-tier

  worker:
    image: $ECR_BASE_URL/voting-app/worker:$TAG
    depends_on:
      redis:
        condition: service_healthy
      db:
        condition: service_healthy
    networks:
      - back-tier

  redis:
    image: redis:alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5
    networks:
      - back-tier

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: "postgres"
      POSTGRES_PASSWORD: "postgres"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5
    networks:
      - back-tier

volumes:
  db-data:

networks:
  front-tier:
  back-tier:
EOF

echo "✅ $COMPOSE_FILE generado con éxito."
echo "🚀 Listo para desplegar con: docker compose -f $COMPOSE_FILE up -d"




# Subir docker-compose a S3

S3_BUCKET="dc-bucket-iz"
S3_KEY="docker-compose/$COMPOSE_FILE"

echo "☁️ Subiendo $COMPOSE_FILE a S3 (s3://$S3_BUCKET/$S3_KEY)..."
aws s3 cp "$COMPOSE_FILE" "s3://$S3_BUCKET/$S3_KEY" --region $AWS_REGION
echo "✅ Archivo subido a S3."
