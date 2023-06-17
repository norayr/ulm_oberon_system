BinDir :=		$(shell pwd)/../../../bin
InstallBinDir :=	$(BinDir)
Targets :=		oblink
InstalledTargets :=	$(patsubst %,$(InstallBinDir)/%,$(Targets))
Parameters :=		BINDIR=$(BinDir)

.PHONY:			install
install:		$(InstalledTargets)
$(InstallBinDir)/oblink:	oblink.sh
			../../../substparams $(Parameters) <$< >$@
			chmod 755 $@
