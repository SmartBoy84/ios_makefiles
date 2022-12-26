TOOLCHAIN:=$(DIYCOMPILE)/toolchain/linux/iphone/bin

APP:=bobbi
ENT:=

# comment out the following to prevent trustcache injection
TRUSTCACHE:=$(APP).tc

IP:=le-carote
ADDR:=root@$(IP)
PORT:=22
UPLOAD_DIR:=/User/Downloads

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
CHECK_TC=[ -z $(TRUSTCACHE) ] ||

FLAGS=$(INCLUDE) $(ARCH) $(CUSTOM)

all: build sign
do: build sign upload run

build:
	@echo "$(arrow)$(green)Building Go app to ${APP}$(end)"
	@$(GO_CUSTOM) CC="$(CC)" go build -o ${APP}

sign:
	@echo "$(arrow)$(green)Signing ${APP}$(red)"
	@chmod +x ${APP}
	@$(TOOLCHAIN)/ldid -S$(ENT) $(APP)
	@$(CHECK_TC) $(TOOLCHAIN)/trustcache create $(APP).tc $(APP)

upload:
	@echo "$(arrow)$(green)Uploading ${APP}$(end)"
	-@ssh -p $(PORT) $(ADDR) "rm $(UPLOAD_DIR)/$(APP)"
	@scp -P $(PORT) ${APP} ${ADDR}:${UPLOAD_DIR}
	@$(CHECK_TC) scp -P $(PORT) $(APP).tc $(ADDR):/tmp

run:
	@echo "$(arrow)$(green)Running ${APP}$(red)$(end)"
	-@$(CHECK_TC) ssh -p $(PORT) $(ADDR) "/.Fugu14Untether/jailbreakd loadTC /tmp/$(APP).tc"
	@echo ""
	@ssh -p $(PORT) $(ADDR) "$(UPLOAD_DIR)/${APP}"

clean:
	@echo "$(arrow)$(green)Cleaning up!$(end)"
	@rm ${APP} $(APP).tc
