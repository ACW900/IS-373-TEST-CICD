FROM nginx:1.27-alpine

LABEL org.opencontainers.image.source="https://github.com/ACW900/IS-373-TEST-CICD"

ARG GIT_SHA=dev
ARG BUILD_ENV=local
ARG RUN_NUMBER=0

COPY site/ /usr/share/nginx/html/

# Stamp the build so each environment can prove which commit and test run it is serving
RUN printf '{"env":"%s","commit":"%s","run":"%s"}\n' "$BUILD_ENV" "$GIT_SHA" "$RUN_NUMBER" > /usr/share/nginx/html/version.json

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1
