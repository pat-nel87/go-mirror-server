FROM golang:1.23-alpine AS builder

# Install security updates and ca-certificates
RUN apk update && apk upgrade && apk add --no-cache ca-certificates && rm -rf /var/cache/apk/*

WORKDIR /app

# Copy go.mod and go.sum if they exist, otherwise create minimal go.mod
COPY go.* ./
RUN if [ ! -f go.mod ]; then \
        go mod init go-mirror-server; \
    fi && \
    go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o echo-server main.go

# Minimal secure image
FROM alpine:3.19

# Install security updates
RUN apk update && apk upgrade && apk add --no-cache ca-certificates && rm -rf /var/cache/apk/*

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Create app directory and set ownership
RUN mkdir -p /app && chown -R appuser:appgroup /app

WORKDIR /app

# Copy binary and set ownership
COPY --from=builder --chown=appuser:appgroup /app/echo-server .

# Switch to non-root user
USER appuser

EXPOSE 8080
ENTRYPOINT ["./echo-server"]
