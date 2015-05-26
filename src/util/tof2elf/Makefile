BinDir :=		$(shell pwd)/../../../bin
InstallBinDir :=	$(BinDir)
Targets :=		tof2elf
InstalledTargets :=	$(patsubst %,$(InstallBinDir)/%,$(Targets))
LDLIBS :=		-lelf
LDFLAGS :=		-static
CFLAGS :=		-I/usr/include/libelf

.PHONY:			all
all:			$(Targets)

.PHONY:			install
install:		$(InstalledTargets)
$(InstalledTargets):	$(InstallBinDir)/%: %
			mkdir -p $(InstallBinDir)
			cp $< $@
