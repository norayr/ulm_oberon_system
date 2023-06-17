#------------------------------------------------------------------------------
# Makefile for Oberon system documentation
# (c) University of Ulm, SAI, D-7900 Ulm
# afb 8/90
# rev afb 9/90: GNU make
# rev afb 9/90
#    avoid patsubst in association with ":=" assignment to
#    keep environment lists < 5kb
# rev afb 4/92: hierarchical makefiles
#------------------------------------------------------------------------------

Chapter5 :=	$(shell echo *.5)

BinDir :=	../../bin
MiscDir :=	../../misc

InstallLib :=	/home/obsrc/library
InstallMan :=	/home/obsrc/man
InstallHTML :=	/home/www/htdocs/oberon/current/files/man

Release :=	0.5

#------------------------------------------------------------------------------
# installation
#------------------------------------------------------------------------------
Man5 :=		$(InstallMan)/man5
Pages5 =	$(patsubst %,$(Man5)/%, $(Chapter5))
WWWPages :=	$(patsubst %.5,$(InstallHTML)/%.html, $(Chapter5))

.PHONY:		install
install:	$(Pages5) $(WWWPages)

$(Pages5):	$(Man5)/%: %
		rm -f $@
		$(BinDir)/patch_macros \
			-l $(InstallLib) \
			-m $(MiscDir)/macros \
			-r $(Release) \
			$< >$@
		chmod 664 $@

$(WWWPages):	$(InstallHTML)/%.html: %.5
		$(BinDir)/man5tohtml $<
		chmod 664 $@

#------------------------------------------------------------------------------
# cleanup
#------------------------------------------------------------------------------
.PHONY:		clean
clean:
		rcsclean $(Docs)
