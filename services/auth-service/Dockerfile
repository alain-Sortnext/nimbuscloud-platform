FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o auth-service ./cmd/main.go

FROM alpine:3.18
RUN apk --no-cache add ca-certificates wget
WORKDIR /root/
COPY --from=builder /app/auth-service .
EXPOSE 3003
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:3003/healthz || exit 1
CMD ["./auth-service"]
