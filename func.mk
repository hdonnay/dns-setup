define FETCH
@wget -q -O "$(1)" $(2) || curl -s -o "$(1)" $(2)
endef

define CKFILE
@printf '%s\t%s\n' "$(2)" "$(1)" > $(1:.tar.gz=.sha1sum)
endef

define upper
$(shell echo "$(1)" | tr '[:lower:]' '[:upper:]')
endef

define TEMPLATE
clean::
	rm -rf $$($(call upper,$(1))_DIR)*

$(1)-get: $($(call upper,$(1))_TAR)
	@tar xzf $$<

$(1)-%.tar.gz:
	$$(call FETCH,$$@,$($(call upper,$(1))_URL))
	$$(call CKFILE,$$@,$($(call upper,$(1))_CKSM))
	@sha1sum -c $$(@:.tar.gz=.sha1sum) && rm $$(@:.tar.gz=.sha1sum)

endef
