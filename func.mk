define FETCH
$(info fetching $2 to $1)
@wget -q -O "$(1)" $(2) || curl -s -o "$(1)" $(2)
endef

define CKFILE
@printf '%s  %s\n' "$(2)" "$(1)" > $(1:.tar.gz=.sha1sum)
endef

define upper
$(shell echo "$(1)" | tr '[:lower:]' '[:upper:]')
endef

define TEMPLATE
clean::
	rm -rf $($(call upper,$(1))_DIR)

cleanall::
	rm -rf $($(call upper,$(1))_TAR)

$(1)-get: $($(call upper,$(1))_TAR)
	@tar xzf $$<

$(1)-%.tar.gz:
	$$(call FETCH,$$@,$($(call upper,$(1))_URL))
	$$(call CKFILE,$$@,$($(call upper,$(1))_CKSM))
	@sha1sum -c $$(@:.tar.gz=.sha1sum) && rm $$(@:.tar.gz=.sha1sum)

$(1)-build: $(1)-config
	@cd $($(call upper,$(1))_DIR) && $$(MAKE) install
endef

define CHECK_BIN
	@if ! which $(1) >/dev/null 2>&1; then echo $(1) not found!; exit 1; else echo $(1): OK; fi

endef

define CHECK_DIR
	@if ! test -d $(1) ; then echo $(1) not found!; exit 1; else echo $(1): OK; fi

endef
