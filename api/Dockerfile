FROM python:3.8.1-alpine

ENV APP_DIR=/app
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

COPY . $APP_DIR/

WORKDIR $APP_DIR

RUN set -eux \
    && apk add --no-cache --virtual .build-deps build-base \
    libressl-dev libffi-dev gcc musl-dev python3-dev \
    postgresql-dev \
    && pip install --upgrade pip setuptools wheel \
    && pip install -r $APP_DIR/requirements.txt \
    && rm -rf /root/.cache/pip

CMD uvicorn src.main:app --reload --workers 1 --host 0.0.0.0 --port 80

VOLUME ["/static"]

EXPOSE 80