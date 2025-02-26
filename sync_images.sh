#!/bin/bash

# 检查必要的环境变量是否设置
REQUIRED_VARS=("ALIBABA_USER" "ALIBABA_PASS" "SOURCE" "DEST")
for VAR in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!VAR}" ]; then
    echo "错误: 环境变量 $VAR 未设置"
    exit 1
  fi
done

# 默认标签列表，若未提供 TAGS 环境变量则使用默认值
TAGS=${TAGS:-"main cuda ollama dev"}
TAGS_ARRAY=($TAGS)  # 将 TAGS 转换为数组

# 日志输出到标准输出
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 检查并同步每个标签
for TAG in "${TAGS_ARRAY[@]}"; do
  log "检查标签: $TAG"

  # 获取源镜像的 Digest
  SRC_DIGEST=$(skopeo inspect docker://$SOURCE:$TAG | jq -r '.Digest')
  if [ -z "$SRC_DIGEST" ]; then
    log "错误: 无法获取 $SOURCE:$TAG 的 Digest，跳过"
    continue
  fi

  # 检查目标镜像是否存在及其 Digest
  DEST_DIGEST=$(skopeo inspect --creds "$ALIBABA_USER:$ALIBABA_PASS" docker://$DEST:$TAG | jq -r '.Digest' || echo "none")

  # 比较 Digest，若不同则同步
  if [ "$SRC_DIGEST" != "$DEST_DIGEST" ]; then
    log "检测到更新，同步 $TAG"
    skopeo copy --dest-creds "$ALIBABA_USER:$ALIBABA_PASS" \
      docker://$SOURCE:$TAG docker://$DEST:$TAG
    if [ $? -eq 0 ]; then
      log "成功同步 $TAG"
    else
      log "错误: 同步 $TAG 失败"
    fi
  else
    log "$TAG 无更新 (Digest: $SRC_DIGEST)，跳过"
  fi
done