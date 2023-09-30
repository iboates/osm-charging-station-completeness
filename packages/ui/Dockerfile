FROM node:18-alpine

WORKDIR /app

COPY csc-ui/package.json /app/package.json
RUN yarn install

EXPOSE 3000

ENTRYPOINT ["yarn", "dev"]
