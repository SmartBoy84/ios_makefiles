TOOLCHAIN:=$(DIYCOMPILE)/toolchain/linux/iphone/bin

APP:=writexe
FILE:=*.c
ENT:=

# comment out the following to prevent trustcache injection
TRUSTCACHE:=$(APP).tc

INCLUDE:=-I. -L.
ARCH=-target arm64-apple-ios14.4
CUSTOM=-isysroot /home/hamdan/iOS/Theos/sdks/iPhoneOS14.5.sdk
#-I. -Iinclude -Linclude -L.

IP:=le-carote
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
CHECK_TC=[ -z $(TRUSTCACHE) ] ||

FLAGS=$(INCLUDE) $(ARCH) $(CUSTOM)

all: build sign
do: build sign upload run

build:
	@echo "$(arrow)$(green)Compiling ${FILE} to ${APP}$(end)"
	@$(TOOLCHAIN)/clang ${FLAGS} ${FILE} -o ${APP}

sign:
	@echo "$(arrow)$(green)Signing ${APP}$(red)"
	@chmod +x ${APP}
	@$(TOOLCHAIN)/ldid -S$(ENT) $(APP)
	@$(CHECK_TC) $(TOOLCHAIN)/trustcache create $(APP).tc $(APP)

upload:
	@echo "$(arrow)$(green)Uploading ${APP}$(end)"
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
