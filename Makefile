include var.mk
include func.mk

DEP_BINS = $(CC) sha1sum ln
DEP_FILE = /usr/include/$(OS) /usr/include/asm-generic /usr/include/$(ASM)
# order matters on this
PARTS = musl expat libressl unbound nsd
WORK := $(PWD)/work

all: check-deps get-all build-all install-all finish

check-deps:
	$(foreach)

get-all: $(patsubst %,%-get,$(PARTS))

build-all: get-all | $(patsubst %,%-config,$(PARTS))

$(foreach p,$(PARTS),$(eval $(call TEMPLATE,$p)))

musl-config:
	mkdir -p $(WORK)
	cd $(MUSL_DIR) && ./configure --prefix=$(WORK) --syslibdir=$(WORK)/lib --disable-shared
	cd $(MUSL_DIR) && $(MAKE) install

expat-config:
	cd $(EXPAT_DIR) && ./configure --prefix=$(WORK) --disable-shared CC=$(WORK)/bin/musl-gcc

libressl-config:
	cd $(LIBRESSL_DIR) && ./configure --prefix=$(WORK) --disable-shared CC=$(WORK)/bin/musl-gcc

unbound-config:
	cd $(UNBOUND_DIR) && ./configure --prefix=$(WORK) --disable-shared --enable-static-exe CC=$(WORK)/bin/musl-gcc

nsd-config:
	cd $(NSD_DIR) && ./configure --prefix=$(WORK) --disable-option-checking \
		--disable-shared --enable-static-exe CC=$(WORK)/bin/musl-gcc

clean:
	rm -rf $(CLEAN_PAT)

.PHONY: check-deps get-all build-all $(PARTS) \
	$(patsubst %,%-get,$(PARTS)) $(patsubst %,%-config,$(PARTS))
