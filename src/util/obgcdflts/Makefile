BinDir :=		../../../bin
InstallBinDir :=	$(BinDir)
Targets :=		obgcdflts
InstalledTargets :=	$(patsubst %,$(InstallBinDir)/%,$(Targets))

.PHONY:			install
install:		$(InstalledTargets)
$(InstallBinDir)/obgcdflts:	obgcdflts.pl
			perl -c obgcdflts.pl
			cp $< $@
			chmod 755 $@
