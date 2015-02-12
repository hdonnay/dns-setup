include var.mk
include func.mk

DEP_BINS = $(CC) sha1sum ln
DEP_FILE = /usr/include/linux /usr/include/asm-generic /usr/include/asm
# order matters on this
PARTS = musl expat libressl unbound nsd
WORK := $(PWD)/work

all: check-deps get-all build-all install-all finish

check-deps:
	$(foreach)

get-all: $(patsubst %,%-get,$(PARTS))

build-all: | $(patsubst %,%-config,$(PARTS))

$(foreach p,$(PARTS),$(eval $(call TEMPLATE,$p)))

# we're overloading this, as it all needs to be done before we even configure the other packages
musl-config: musl-get
	@mkdir -p $(WORK)
	cd $(MUSL_DIR) && ./configure --prefix=$(WORK) --syslibdir=$(WORK)/lib --disable-shared
	cd $(MUSL_DIR) && $(MAKE) install
	cd $(WORK)/include && { $(foreach l,$(DEP_FILE),ln -sf $l ;) }

expat-config: expat-get
	cd $(EXPAT_DIR) && ./configure --prefix=$(WORK) --disable-shared CC=$(WORK)/bin/musl-gcc

libressl-config: libressl-get
	cd $(LIBRESSL_DIR) && ./configure --prefix=$(WORK) --disable-shared CC=$(WORK)/bin/musl-gcc

unbound-config: unbound-get
	cd $(UNBOUND_DIR) && ./configure --prefix=$(WORK) --disable-shared --enable-static-exe CC=$(WORK)/bin/musl-gcc

nsd-config: nsd-get
	cd $(NSD_DIR) && ./configure --prefix=$(WORK) --disable-option-checking \
		--disable-shared --enable-static-exe CC=$(WORK)/bin/musl-gcc

cleanall: clean
	rm -rf work

.PHONY: check-deps get-all build-all $(PARTS) \
	$(patsubst %,%-get,$(PARTS)) $(patsubst %,%-config,$(PARTS))
