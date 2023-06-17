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

Chapter3 :=	$(shell echo *.3)

BinDir :=	../../bin
MiscDir :=	../../misc

InstallLib :=	/usr/local/lib/oberon
InstallMan :=	/home/obsrc/man
InstallHTML :=	/home/www/htdocs/oberon/current/lib/man

Release :=	0.5

#------------------------------------------------------------------------------
# installation
#------------------------------------------------------------------------------
Man3 :=		$(InstallMan)/man3
Pages3 =	$(patsubst %,$(Man3)/%, $(Chapter3))
CatMan3 :=	$(InstallMan)/cat3
CatPages3 =	$(patsubst %,$(CatMan3)/%, $(Chapter3))
WWWPages :=	$(patsubst %.3,$(InstallHTML)/%.html, $(Chapter3))

.PHONY:		install
install:	$(Pages3) $(CatPages3) $(WWWPages)

$(Pages3):	$(Man3)/%: %
		rm -f $@
		$(BinDir)/patch_macros \
			-l $(InstallLib) \
			-m $(MiscDir)/macros \
			-r $(Release) \
			$< >$@
		-chmod 664 $@

$(CatPages3):	$(CatMan3)/%: $(Man3)/%
		rm -f $@
		groff -t -e -Tlatin1 -mgan $< >$@

$(WWWPages):	$(InstallHTML)/%.html: %.3
		$(BinDir)/man3tohtml $<
		-chmod 664 $@

#------------------------------------------------------------------------------
# cleanup & checkout
#------------------------------------------------------------------------------
.PHONY:		checkout clean
checkout:	$(Chapter3)
clean:
		rcsclean $(Docs)
