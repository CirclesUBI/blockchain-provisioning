FROM ethereum/client-go:v1.8.12

RUN apk update && apk add bind-tools curl

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT /entrypoint.sh "${SYNC_MODE}" "${NODE_NAME}"
