#------------------------------------------------------------------------------
Dirs := genobrts load_libsources mkoblib obbuild oblink \
	obmkinit obstage obgcdflts \
	start_cdbd start_pons tof2elf
#------------------------------------------------------------------------------
define propagate-target
@for dir in $(Dirs) ;\
do	cd $$dir; \
	echo make $@ in $$dir; \
	$(MAKE) $@ || break; \
	cd ..; \
done
endef
#------------------------------------------------------------------------------

.PHONY: install
install:	; $(propagate-target)
