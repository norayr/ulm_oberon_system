#------------------------------------------------------------------------------
# Makefile for the Oberon Manual Pages
# afb 4/92
#------------------------------------------------------------------------------

ManDirs :=	man1 man3 man5
BinDir :=	../bin
MiscDir :=	../misc

InstallLib :=	/home/obsrc/library
InstallMan :=	/home/obsrc/man

Release :=	0.5

#------------------------------------------------------------------------------
define propagate-target
@for dir in $(ManDirs) ;\
do	cd $$dir; \
	echo make $@ in $$dir; \
	$(MAKE) \
		BinDir=../$(BinDir) \
		MiscDir=../$(MiscDir) \
		InstallLib=$(InstallLib) \
		InstallMan=$(InstallMan) \
		Release=$(Release) \
		$@ || break; \
	cd ..; \
done
endef
#------------------------------------------------------------------------------

.PHONY: install
install:	; $(propagate-target)

.PHONY: clean
clean:		; $(propagate-target)
