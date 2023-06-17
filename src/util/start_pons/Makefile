DestDir :=		$(shell pwd)/../../..
BinDir :=		$(DestDir)/bin
PonsDir :=		$(DestDir)/var/pons
InstallBinDir :=	$(BinDir)
Targets :=		start_pons
InstalledTargets :=	$(patsubst %,$(InstallBinDir)/%,$(Targets))
Parameters :=		BASEDIR=$(DestDir) BINDIR=$(BinDir) \
			PONSDIR=$(PonsDir) ONS_ROOT=$(ONSRoot)

.PHONY:			install
install:		$(InstalledTargets)
$(InstallBinDir)/start_pons:	start_pons.sh
			../../../substparams $(Parameters) <$< >$@
			chmod 755 $@
