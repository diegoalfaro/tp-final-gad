FROM postgres:14

ENV DATA_DIR=/db_data
ENV EXTENSIONS_DIR=/extensions
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y xxd git make gcc libpq-dev postgresql-server-dev-14 libgd-dev

WORKDIR $EXTENSIONS_DIR
COPY ./extensions $EXTENSIONS_DIR/
WORKDIR $EXTENSIONS_DIR/imagecomparer
RUN make install

COPY ./scripts/1-database.sql /docker-entrypoint-initdb.d/1-database.sql
COPY ./scripts/2-schema.sql /docker-entrypoint-initdb.d/2-schema.sql
COPY ./scripts/3-triggers.sql /docker-entrypoint-initdb.d/3-triggers.sql
COPY ./scripts/4-stored_procedures.sql /docker-entrypoint-initdb.d/4-stored_procedures.sql
COPY ./scripts/5-data.sql /docker-entrypoint-initdb.d/5-data.sql

VOLUME ["/static"]

WORKDIR $DATA_DIR
EXPOSE 5432