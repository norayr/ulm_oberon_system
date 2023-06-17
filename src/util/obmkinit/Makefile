DestDir :=		$(shell pwd)/../../..
BinDir :=		$(DestDir)/bin
PonsDir :=		$(DestDir)/var/pons
CDBDDir :=		$(DestDir)/var/cdbd
CDBDir :=		/pub/cdb/oberon
InstallBinDir :=	$(BinDir)
Targets :=		obmk_suse_init_cdbd obmk_suse_init_pons
InstalledTargets :=	$(patsubst %,$(InstallBinDir)/%,$(Targets))
Parameters :=		BASEDIR=$(DestDir) BINDIR=$(BinDir) \
			PONSDIR=$(PonsDir) ONS_ROOT=$(ONSRoot) \
			CDBDDIR=$(CDBDDir) CDBDIR=$(CDBDir) \
			ONS_PORT=$(ONSPort) CDBD_PORT=$(CDBDPort) \
			INTENSITY=$(IntensityDir)/cdbd

.PHONY:			install
install:		$(InstalledTargets)
$(InstallBinDir)/obmk_suse_init_cdbd:	obmk_suse_init_cdbd.sh
			../../../substparams $(Parameters) <$< >$@
			chmod 755 $@
$(InstallBinDir)/obmk_suse_init_pons:	obmk_suse_init_pons.sh
			../../../substparams $(Parameters) <$< >$@
			chmod 755 $@
