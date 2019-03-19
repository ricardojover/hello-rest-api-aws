FROM alpine:3.9

WORKDIR /hello

COPY requirements.txt .

RUN apk --no-cache update && \
    apk --no-cache add bash curl python3 mysql-dev postgresql-libs && \
    apk add --no-cache --virtual .build-deps python3-dev gcc musl-dev postgresql-dev && \ 
    python3 -m pip install -r requirements.txt --no-cache-dir && \
    apk del --purge .build-deps
    
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY src .

ENTRYPOINT ["bash", "-c", "/usr/local/bin/entrypoint.sh"]
