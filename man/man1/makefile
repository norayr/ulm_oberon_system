#------------------------------------------------------------------------------
# Makefile for Oberon system documentation
# (c) University of Ulm, SAI, D-89069 Ulm
# afb 8/90
# rev afb 9/90: GNU make
# rev afb 9/90
#    avoid patsubst in association with ":=" assignment to
#    keep environment lists < 5kb
# rev afb 4/92: hierarchical makefiles
#------------------------------------------------------------------------------

Chapter1 :=	$(shell echo *.1)
BinDir :=	../../bin
MiscDir :=	../../misc

InstallLib :=	/home/obsrc/library
InstallMan :=	/home/obsrc/man
InstallHTML :=	/home/www/htdocs/oberon/current/tools/man

Release :=	0.5

#------------------------------------------------------------------------------
# installation
#------------------------------------------------------------------------------
Man1 :=		$(InstallMan)/man1
Pages1 =	$(patsubst %,$(Man1)/%, $(Chapter1))
WWWPages :=	$(patsubst %.1,$(InstallHTML)/%.html, $(Chapter1))

.PHONY:		install
install:	$(Pages1) $(WWWPages)

$(Pages1):	$(Man1)/%: %
		rm -f $@
		$(BinDir)/patch_macros \
			-l $(InstallLib) \
			-m $(MiscDir)/macros \
			-r $(Release) \
			$< >$@
		chmod 664 $@

$(WWWPages):	$(InstallHTML)/%.html: %.1
		$(BinDir)/man1tohtml $<
		chmod 664 $@

#------------------------------------------------------------------------------
# cleanup
#------------------------------------------------------------------------------
.PHONY:		clean
clean:
		rcsclean $(Docs)
