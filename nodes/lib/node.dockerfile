FROM ethereum/client-go:v1.8.12

RUN apk update && apk add bind-tools curl

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT sh /entrypoint.sh "${NODE_TYPE}"
