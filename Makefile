NAME := sdl-cli
MODULE := github.com/marcelsud/sdl-cli

BIN_DIR := dist
PLATFORMS := \
	linux/amd64 \
	linux/arm64 \
	darwin/amd64 \
	darwin/arm64 \
	windows/amd64

.PHONY: all build clean fmt test release

all: build

release: build
	@./tools/deploy-artifacts.sh

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
		UOS=$$OS; \
		UARCH=$$( [ "$$ARCH" = "amd64" ] && echo "x86_64" || echo "arm64" ); \
		BIN=$(BIN_DIR)/$(NAME)_$$UOS\_$$UARCH$$EXT; \
		echo "==> $$OS/$$ARCH -> $$BIN.tar.gz"; \
		GOOS=$$OS GOARCH=$$ARCH go build -o $(BIN_DIR)/sdl . || exit 1; \
		tar -C $(BIN_DIR) -czf $$BIN.tar.gz sdl || exit 1; \
		rm -f $(BIN_DIR)/sdl; \
	done
