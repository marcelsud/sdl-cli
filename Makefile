NAME := sdl
MODULE := github.com/marcelsud/sdl-cli

BIN_DIR := dist
PLATFORMS := \
	linux/amd64 \
	linux/arm64 \
	darwin/amd64 \
	darwin/arm64 \
	windows/amd64

.PHONY: all build clean fmt test

all: build

fmt:
	go fmt ./...

test:
	go test ./...

clean:
	rm -rf $(BIN_DIR)

build: clean
	@mkdir -p $(BIN_DIR)
	@for plat in $(PLATFORMS); do \
		OS=$${plat%%/*}; ARCH=$${plat##*/}; \
		EXT=$$( [ "$$OS" = "windows" ] && echo ".exe" ); \
		OUT=$(BIN_DIR)/$(NAME)-$$OS-$$ARCH$$EXT; \
		echo "==> $$OS/$$ARCH -> $$OUT"; \
		GOOS=$$OS GOARCH=$$ARCH go build -o $$OUT . || exit 1; \
	done
