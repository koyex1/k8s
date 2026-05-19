FROM golang:1.25-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY . .

RUN go build -o cart .

# -----------------------

FROM alpine:latest

WORKDIR /root/

COPY --from=builder /app/cart .

EXPOSE 8080

CMD ["./cart"]