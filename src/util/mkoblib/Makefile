BinDir :=		$(shell pwd)/../../../bin
InstallBinDir :=	$(BinDir)
Targets :=		mkoblib
InstalledTargets :=	$(patsubst %,$(InstallBinDir)/%,$(Targets))
Parameters :=		BINDIR=$(BinDir)

.PHONY:			install
install:		$(InstalledTargets)
$(InstallBinDir)/mkoblib:	mkoblib.sh
			../../../substparams $(Parameters) <$< >$@
			chmod 755 $@
