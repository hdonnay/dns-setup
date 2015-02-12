include config.mk
include var.mk
include func.mk

DEP_BINS = $(CC) sha1sum ln
DEP_FILE = /usr/include/linux /usr/include/asm-generic /usr/include/asm
# order matters on this
PARTS = musl expat libressl unbound nsd
WORK := $(PWD)/work
OPTS := CC=$(WORK)/bin/musl-gcc LDFLAGS=-L$(WORK)/lib CPPFLAGS=-I$(WORK)/include

all: check-deps get-all build-all finish

check-deps:
	mkdir -p $(PWD)/out
	ln -sf $(PWD)/out $(DNS)

get-all: $(patsubst %,%-get,$(PARTS))

build-all: check-deps | $(patsubst %,%-build,$(PARTS))

finish:
	@

$(foreach p,$(PARTS),$(eval $(call TEMPLATE,$p)))

# we're overloading this, as it all needs to be done before we even configure the other packages
musl-config: musl-get
	@mkdir -p $(WORK)
	cd $(MUSL_DIR) && ./configure --prefix=$(WORK) --syslibdir=$(WORK)/lib --disable-shared\
		>/dev/null
	cd $(MUSL_DIR) && $(MAKE) install
	cd $(WORK)/include && { $(foreach l,$(DEP_FILE),ln -sf $l ;) }

expat-config: expat-get
	cd $(EXPAT_DIR) && ./configure --prefix=$(WORK) --disable-shared $(OPTS)\
		>/dev/null

libressl-config: libressl-get
	cd $(LIBRESSL_DIR) && ./configure --prefix=$(WORK) --disable-shared $(OPTS)\
		>/dev/null

unbound-config: unbound-get
	cd $(UNBOUND_DIR) && ./configure --prefix=$(WORK) --with-username=nobody \
		--sysconfdir=/etc --with-conf-file=./unbound.conf --disable-flto --disable-shared \
		--with-ssl=$(WORK) --with-libexpat=$(WORK) $(OPTS) >/dev/null

nsd-config: nsd-get
	cd $(NSD_DIR) && ./configure --prefix=$(WORK) \
		--with-configdir=. --with-user=nobody \
		--disable-flto --with-libevent=no --with-ssl=$(WORK) $(OPTS)\
		>/dev/null


cleanall:: clean
	rm -rf $(WORK) $(PWD)/out

.PHONY: check-deps get-all build-all $(PARTS) \
	$(patsubst %,%-get,$(PARTS)) $(patsubst %,%-config,$(PARTS))
