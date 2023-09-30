FROM ubuntu:22.04 AS build-stage
WORKDIR /newchain

# these lines needed to avoid intermittent hash mismatch caused by repo cache
RUN echo "Acquire::http::Pipeline-Depth 0;" > /etc/apt/apt.conf.d/99custom && \
    echo "Acquire::http::No-Cache true;" >> /etc/apt/apt.conf.d/99custom && \
    echo "Acquire::BrokenProxy    true;" >> /etc/apt/apt.conf.d/99custom

RUN apt-get update -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y ca-certificates git golang make

COPY go.mod go.sum .
RUN go mod download

COPY . .

RUN VERSION=$(echo $(git describe --tags 2>/dev/null || echo v0.0.0) | head -1 | sed 's/^v//') && \
    COMMIT=$(git log -1 --format='%H') && \
    ldflags='-X github.com/cosmos/cosmos-sdk/version.Name=newchain \
        -X github.com/cosmos/cosmos-sdk/version.ServerName=newchaind \
        -X github.com/cosmos/cosmos-sdk/version.Version=$(VERSION) \
        -X github.com/cosmos/cosmos-sdk/version.Commit=$(COMMIT) \
        -X "github.com/cosmos/cosmos-sdk/version.BuildTags=netgo,"' && \
    GOOS=linux GOARCH=amd64 CGO_ENABLED=1 go build -mod=readonly -tags netgo -ldflags "${ldflags}" -o /tmp ./cmd/newchaind

FROM scratch AS export-stage
COPY --from=build-stage /tmp/newchaind /newchaind
