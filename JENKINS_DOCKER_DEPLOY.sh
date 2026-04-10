set -euo pipefail

PROJECT_DIR="${WORKSPACE:?WORKSPACE is required}"
IMAGE_NAME="${IMAGE_NAME:-hys-uptime-kuma:latest}"
CONTAINER_NAME="${CONTAINER_NAME:-uptime-kuma}"
DATA_DIR="${DATA_DIR:-$WORKSPACE/data}"
BRANCH="${BRANCH:-master}"
HOST_PORT="${HOST_PORT:-3001}"

DB_HOST="${DB_HOST:?DB_HOST is required}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:?DB_NAME is required}"
DB_USER="${DB_USER:?DB_USER is required}"
DB_PASS="${DB_PASS:?DB_PASS is required}"

cd "$PROJECT_DIR"

echo "===> 当前目录: $(pwd)"
echo "===> 检查 Docker"
docker --version

echo "===> 拉取最新代码"
git fetch --all
git checkout "$BRANCH"
git reset --hard "origin/$BRANCH"

echo "===> 准备数据目录"
mkdir -p "$DATA_DIR"

echo "===> 写入数据库配置"
cat > "$DATA_DIR/db-config.json" <<EOF
{
  "type": "mariadb",
  "hostname": "$DB_HOST",
  "port": "$DB_PORT",
  "dbName": "$DB_NAME",
  "username": "$DB_USER",
  "password": "$DB_PASS"
}
EOF

echo "===> 构建镜像"
docker build -f docker/dockerfile --target release -t "$IMAGE_NAME" .

echo "===> 删除旧容器"
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

echo "===> 启动新容器"
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  -p "$HOST_PORT:3001" \
  -v "$DATA_DIR:/app/data" \
  "$IMAGE_NAME"

echo "===> 检查容器状态"
docker ps | grep "$CONTAINER_NAME" || true
docker logs --tail 100 "$CONTAINER_NAME" || true

echo "===> 部署完成"
