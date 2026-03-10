BinDir :=		$(shell pwd)/../../../bin
InstallBinDir :=	$(BinDir)
Targets :=		oblink oberon-i386.ld
InstalledTargets :=	$(patsubst %,$(InstallBinDir)/%,$(Targets))
Parameters :=		BINDIR=$(BinDir)

.PHONY:			install
install:		$(InstalledTargets)
$(InstallBinDir)/oblink:	oblink.sh
			../../../substparams $(Parameters) <$< >$@
			chmod 755 $@
$(InstallBinDir)/oberon-i386.ld:	oberon-i386.ld
			mkdir -p $(InstallBinDir)
			cp $< $@
