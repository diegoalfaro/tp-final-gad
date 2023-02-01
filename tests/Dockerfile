FROM node

ENV APP_DIR=/app
COPY . $APP_DIR/
WORKDIR $APP_DIR
RUN npm install
VOLUME ["/static"]
ENTRYPOINT [ "npm", "run", "test" ]
