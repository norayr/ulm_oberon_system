DestDir :=		$(shell pwd)/../../..
BinDir :=		$(DestDir)/bin
InstallBinDir :=	$(BinDir)
Targets :=		obbuild
InstalledTargets :=	$(patsubst %,$(InstallBinDir)/%,$(Targets))
Parameters :=		BASEDIR=$(DestDir) BINDIR=$(BinDir) DBAUTH=$(DBAuth) \
			CDBDIR=$(CDBDir)

.PHONY:			install
install:		$(InstalledTargets)
$(InstallBinDir)/obbuild:	obbuild.sh
			../../../substparams $(Parameters) <$< >$@
			chmod 755 $@
