FROM node:18-alpine

WORKDIR /app

COPY csc-ui ./
RUN yarn install

EXPOSE 3000

ENTRYPOINT ["yarn", "dev", "--host"]
