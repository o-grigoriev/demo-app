FROM node:slim

WORKDIR /usr/src/

# Build dependencies
COPY  package.json .
RUN set -xe \
    && npm install 

# Copy source code
COPY . .

EXPOSE 3000
CMD ["npm", "start"]
