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

LABEL org.opencontainers.image.source=https://github.com/lwmacct/260403-bbiz-vm-ikuai
LABEL org.opencontainers.image.description="-- IGNORE --"
LABEL org.opencontainers.image.licenses=MIT
