include config.mk
include var.mk
include func.mk

DEP_BINS = $(CC) $(LD) sha1sum pkg-config strip
# my debian wheezy box has things in a odd location?
DEP_DIRS = /usr/include/linux /usr/include/asm-generic \
		/usr/include$(if $(wildcard /usr/include/asm/*),,/x86_64-linux-gnu)/asm
# order matters on this
PARTS = musl expat libressl unbound nsd
WORK := $(PWD)/work
OUT := $(PWD)/dns
OPTS := CC=$(WORK)/bin/musl-gcc LDFLAGS=-L$(WORK)/lib CPPFLAGS=-I$(WORK)/include
ROOT_HINTS := 'http://www.internic.net/domain/named.root'

all: check-deps get-all build-all finish

check-deps:
	@mkdir -p $(OUT)/nsd $(OUT)/unbound
	@ln -sf $(OUT) $(DNS)
	$(foreach x,$(DEP_BINS),$(call CHECK_BIN,$x))
	$(foreach x,$(DEP_DIRS),$(call CHECK_DIR,$x))

get-all: $(patsubst %,%-get,$(PARTS))

build-all: check-deps | $(patsubst %,%-build,$(PARTS))

finish: build-all
	cp $(WORK)/sbin/nsd* $(OUT)/nsd/
	cp $(NSD_DIR)/nsd.conf.sample $(OUT)/nsd/nsd.conf
	cp $(WORK)/sbin/unbound* $(OUT)/unbound/
	$(call FETCH,$(OUT)/unbound/named.root,$(ROOT_HINTS))
	cp $(UNBOUND_DIR)/unbound.conf $(OUT)/unbound/unbound.conf
	find $(OUT) -executable -a -type f | grep -v 'setup$$' | xargs strip
	tar cJf ./dns.tar.xz \
		-C $$(dirname $(OUT)) \
		--owner=root --group=root \
		$$(basename $(OUT))

$(foreach p,$(PARTS),$(eval $(call TEMPLATE,$p)))

# we're overloading this, as it all needs to be done before we even configure the other packages
musl-config: musl-get
	@mkdir -p $(WORK)
	cd $(MUSL_DIR) && ./configure \
		--prefix=$(WORK) \
		--syslibdir=$(WORK)/lib \
		--disable-shared >/dev/null
	cd $(MUSL_DIR) && $(MAKE) install
	cd $(WORK)/include && { $(foreach l,$(DEP_DIRS),ln -sf $l ;) }

expat-config: expat-get
	cd $(EXPAT_DIR) && ./configure \
		--prefix=$(WORK) \
		--disable-shared \
		$(OPTS) \
		>/dev/null

libressl-config: libressl-get
	cd $(LIBRESSL_DIR) && ./configure \
		--prefix=$(WORK) \
		--disable-shared \
		$(OPTS) \
		>/dev/null

unbound-config: unbound-get
	cd $(UNBOUND_DIR) && ./configure \
		--prefix=$(WORK) \
		--with-username=nobody --sysconfdir=/etc --with-conf-file=./unbound.conf \
		--disable-flto --disable-shared \
		--with-ssl=$(WORK) \
		--with-libexpat=$(WORK) \
		$(OPTS) \
		>/dev/null

nsd-config: nsd-get
	cd $(NSD_DIR) && ./configure \
		--prefix=$(WORK) \
		--with-configdir=. --with-user=nobody --disable-flto \
		--with-libevent=no \
		--with-ssl=$(WORK) \
		$(OPTS) \
		>/dev/null

clean::
	rm -rf $(WORK)

cleanall:: clean
	rm -rf $(OUT)

.PHONY: check-deps get-all build-all $(PARTS) \
	$(patsubst %,%-get,$(PARTS)) $(patsubst %,%-config,$(PARTS))
