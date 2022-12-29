TOOLCHAIN:=$(DIYCOMPILE)/toolchain/linux/iphone/bin

APP:=writexeboi
FILE:=*.c
ENT:=

# comment out the following to prevent trustcache injection
TRUST_BIN:=/trust

INCLUDE:=-I. -L.
ARCH=-target arm64-apple-ios14.4
CUSTOM=-isysroot /home/hamdan/iOS/Theos/sdks/iPhoneOS14.5.sdk
#-I. -Iinclude -Linclude -L.

IP:=le-carote.strax
ADDR:=root@$(IP)
PORT:=44
UPLOAD_DIR:=/

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
	@echo "$(arrow)$(green)Compiling ${FILE} to ${APP}$(end)"
	@mkdir .build $(SHUTUP)
	@$(TOOLCHAIN)/clang ${FLAGS} ${FILE} -o .build/${APP}

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
