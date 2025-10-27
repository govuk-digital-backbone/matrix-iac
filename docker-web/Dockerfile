FROM ghcr.io/element-hq/element-web:v1.12.2

COPY 01-pre-run.sh /docker-entrypoint.d/

VOLUME /custom-config/

HEALTHCHECK --start-period=10s CMD wget -q --spider http://localhost:8080/config.json
