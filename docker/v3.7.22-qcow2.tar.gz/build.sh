#!/usr/bin/env bash
# shellcheck disable=SC2317
# document https://www.yuque.com/lwmacct/docker/buildx

__main() {
  {
    _sh_path=$(realpath "$(ps -p $$ -o args= 2>/dev/null | awk '{print $2}')")    # 当前脚本路径
    _dir_name=$(echo "$_sh_path" | awk -F '/' '{print $(NF-1)}')                  # 当前目录名
    _pro_name=$(git remote get-url origin | head -n1 | xargs -r basename -s .git) # 当前仓库名
    _image="${_pro_name}:$_dir_name"
  }

  _dockerfile=$(
    cat <<"EOF"
# syntax=docker/dockerfile:1.7
# 第一阶段
FROM alpine:latest AS downloader
RUN set -eux; \
  sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories; \
  apk add --no-cache github-cli
RUN --mount=type=secret,id=GH_TOKEN set -eux; \
  export GH_TOKEN="$(cat /run/secrets/GH_TOKEN)"; \
  test -n "$GH_TOKEN"; \
  gh release download v0.1.260403 \
    -R lwmacct/260403-bbiz-vm-ikuai \
    -p "iKuai8_x64_3.7.22_qcow2.tar.gz" \
    -D /root/

# 第二阶段
FROM alpine:latest
RUN set -eux; \
  sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories; \
  apk add --no-cache tini bash curl jq; \
  echo;

# 复制第一阶段的产物
COPY --from=downloader /root/iKuai8_x64_3.7.22_qcow2.tar.gz /root

SHELL ["/bin/bash", "-lc"]
ENTRYPOINT ["tini", "--"]
CMD ["bash"]

LABEL org.opencontainers.image.source=$_ghcr_source
LABEL org.opencontainers.image.description="-- IGNORE --"
LABEL org.opencontainers.image.licenses=MIT
EOF
  )
  {
    cd "$(dirname "$_sh_path")" || exit 1
    echo "$_dockerfile" >Dockerfile

    _ghcr_source=$(git remote get-url origin | head -n1 | sed 's|git@github.com:|https://github.com/|' | sed 's|.git$||')
    sed -i "s|\$_ghcr_source|$_ghcr_source|g" Dockerfile
  }
  {
    if command -v sponge >/dev/null 2>&1; then
      jq 'del(.credsStore)' ~/.docker/config.json | sponge ~/.docker/config.json
    else
      jq 'del(.credsStore)' ~/.docker/config.json >~/.docker/config.json.tmp && mv ~/.docker/config.json.tmp ~/.docker/config.json
    fi
  }
  {
    _registry="ghcr.io/lwmacct" # 托管平台, 如果是 docker.io 则可以只填写用户名
    _repository="$_registry/$_image"
    _buildcache="$_registry/$_pro_name:cache"
    echo "image: $_repository"
    echo "cache: $_buildcache"
    echo "-----------------------------------"
    : "${GH_TOKEN:?GH_TOKEN environment variable is required}"
    docker buildx build --builder default --platform linux/amd64 \
      --secret id=GH_TOKEN,env=GH_TOKEN \
      -t "$_repository" --network host --progress plain --load . && {
      # false/false
      if false; then
        docker rm -f sss >/dev/null 2>&1 || true
        docker run -itd --name=sss \
          --restart=unless-stopped \
          --network=host \
          --privileged=false \
          "$_repository"
        docker exec -it sss bash
      fi
      docker push "$_repository"
    }
  }
}

__main

__help() {
  cat >/dev/null <<"EOF"
这里可以写一些备注

ghcr.io/lwmacct/260403-bbiz-vm-ikuai:v3.7.22-qcow2.tar.gz

EOF
}
