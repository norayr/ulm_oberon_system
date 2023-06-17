DestDir :=		$(shell pwd)/../../..
BinDir :=		$(DestDir)/bin
CDBDDir :=		$(DestDir)/var/cdbd
InstallBinDir :=	$(BinDir)
Targets :=		start_cdbd
InstalledTargets :=	$(patsubst %,$(InstallBinDir)/%,$(Targets))
Parameters :=		BASEDIR=$(DestDir) BINDIR=$(BinDir) \
			CDBDDIR=$(CDBDDir) ONS_ROOT=$(ONSRoot) \
			INTENSITY=$(IntensityDir)/cdbd

.PHONY:			install
install:		$(InstalledTargets)
$(InstallBinDir)/start_cdbd:	start_cdbd.sh
			../../../substparams $(Parameters) <$< >$@
			chmod 755 $@
