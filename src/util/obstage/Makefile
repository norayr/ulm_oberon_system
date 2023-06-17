DestDir :=		$(shell pwd)/../../..
BinDir :=		$(DestDir)/bin
InstallBinDir :=	$(BinDir)
Targets :=		mk_obstage run_obstage
InstalledTargets :=	$(patsubst %,$(InstallBinDir)/%,$(Targets))

.PHONY:			install
install:		$(InstalledTargets)
$(InstalledTargets):	$(InstallBinDir)/%: %.sh
			cp $< $@
			chmod 755 $@
