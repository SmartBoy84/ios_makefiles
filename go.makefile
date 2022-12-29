TOOLCHAIN:=$(DIYCOMPILE)/toolchain/linux/iphone/bin

APP:=bobbi
ENT:=

# comment out the following to prevent trustcache injection
TRUST_BIN:=/trust

IP:=le-carote.strax
ADDR:=root@$(IP)
PORT:=44
UPLOAD_DIR:=/

ARCH=arm64
OS=14.4

# clang shizzle
CLANG_FLAGS:=
SDK:=$(THEOS)/sdks/iPhoneOS14.5.sdk

# go compiler arguments
GO_FLAGS:=

# main c compilation
GO_CUSTOM:=CGO_ENABLED=1 GOARCH=$(ARCH) GOOS=ios $(GO_FLAGS)
CLANG_CUSTOM:=-isysroot $(SDK) -target $(ARCH)-apple-ios$(OS) $(CLANG_FLAGS)

CC:=$(TOOLCHAIN)/clang $(CLANG_CUSTOM)

# end of configurable variables
green=\033[0;32m
red=\033[0;31m
blue=\033[0;34m
end=\033[0m
arrow=$(red)=> $(end)
MUTE= 2>/dev/null; true

RERUN=$(MAKE) --no-print-directory
SHUTUP=2> /dev/null ||:

FLAGS=$(INCLUDE) $(ARCH) $(CUSTOM)

all: build sign

ifdef TRUST_BIN
do: build sign upload inject run
else
do: build sign upload run
endif

build:
	@echo "$(arrow)$(green)Building Go app to ${APP}$(end)"
	@mkdir .build $(SHUTUP)
	@$(GO_CUSTOM) CC="$(CC)" go build -o .build/${APP}

sign:
	@echo "$(arrow)$(green)Signing ${APP}$(red)"
	@chmod +x .build/${APP}
	@$(TOOLCHAIN)/ldid -S$(ENT) .build/$(APP)

upload:
	@echo "$(arrow)$(green)Uploading ${APP}$(end)"
	-@ssh -p $(PORT) $(ADDR) "rm $(UPLOAD_DIR)/$(APP)" $(SHUTUP)
	@scp -P $(PORT) .build/${APP} ${ADDR}:${UPLOAD_DIR}

inject:
	@echo "$(arrow)$(green)Injecting trustcache$(red)$(end)"
	@ssh -p $(PORT) $(ADDR) "$(TRUST_BIN) $(UPLOAD_DIR)/$(APP) > /dev/null"

run:
	@echo "$(arrow)$(green)Running ${APP}$(red)$(end)"
	@echo ""
	@ssh -p $(PORT) $(ADDR) "$(UPLOAD_DIR)/${APP}"

clean:
	@echo "$(arrow)$(green)Cleaning up!$(end)"
	@rm -r .build
