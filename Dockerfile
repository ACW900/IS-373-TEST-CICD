FROM nginx:1.27-alpine

LABEL org.opencontainers.image.source="https://github.com/ACW900/IS-373-TEST-CICD"

ARG GIT_SHA=dev
ARG BUILD_ENV=local

COPY site/ /usr/share/nginx/html/

# Stamp the build so each environment can prove which commit it is serving
RUN printf '{"env":"%s","commit":"%s"}\n' "$BUILD_ENV" "$GIT_SHA" > /usr/share/nginx/html/version.json

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1
