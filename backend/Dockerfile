# syntax=docker/dockerfile:1
# ---- Build Stage ----
FROM golang:1.25-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
# Cache mounts speed up local BuildKit builds; kaniko ignores them and relies on --cache=true
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

COPY . .

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" -o momo-api ./cmd/api

# ---- Final Stage ----
FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=builder /app/momo-api /momo-api

EXPOSE 8081

ENTRYPOINT ["/momo-api"]