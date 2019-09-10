FROM alpine:latest AS web
ARG NODEJS_VERSION=10.16.3-r0
ARG YARN_VERSION=1.17.3
RUN apk update && \
    apk add nodejs=${NODEJS_VERSION} nodejs-npm=${NODEJS_VERSION} && \
    npm config set unsafe-perm true && \
    npm install --global yarn@${YARN_VERSION}
ADD web /web
WORKDIR /web
RUN yarn && yarn build

FROM golang:1.13.0-alpine3.10 AS binary
ADD . /go/src/ects
WORKDIR /go/src/ects
COPY --from=web /web/dist /go/src/ects/web/dist
RUN apk update && \
    apk add git && \
    cd $GOPATH/src && \
    go get -u github.com/shuLhan/go-bindata/... && \
    cd $GOPATH/src/ects && \
    go-bindata -pkg web -o web/bindata.go web/dist/...
RUN go mod tidy && \
    GOOS=linux go build -ldflags "-s -w" -o "bin/ects_linux" main.go

FROM alpine:3.10
COPY --from=binary /go/src/ects/bin/ects_linux /usr/local/bin/ects
EXPOSE 9701
CMD ["ects"]