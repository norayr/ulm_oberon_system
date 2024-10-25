# DestDir, BinDir etc are the paths that get burnt into the scripts
# InstallDir, InstallBinDir etc are the paths where we copy the files to;
# both sets are by default equal; however in case of package constructions
# we set InstallDir etc to the package construction area and DestDir etc
# to the final destination which is created later on by the package
Root := $(shell pwd)
DestDir := $(Root)
InstallDir := $(DestDir)
BinDir := $(DestDir)/bin
EtcDir := $(DestDir)/etc
IntensityDir := $(EtcDir)/intensity
InstallBinDir := $(InstallDir)/bin
DBDir := $(DestDir)/var/cdbd
InstallDBDir := $(InstallDir)/var/cdbd
DBAuth := $(DBDir)/write
VarDir := $(DestDir)/var
PonsDir := $(VarDir)/pons
CDBDDir := $(VarDir)/cdbd
CDBDir := /pub/cdb/oberon
ManDir := $(DestDir)/man
SrcDir := $(DestDir)/src/oberon
InitDir := $(DestDir)/etc/init.d
InstallPonsDir := $(InstallDir)/var/pons
InstallManDir := $(InstallDir)/man
InstallSrcDir := $(InstallDir)/src
InstallEtcDir := $(InstallDir)/etc
InstallIntensityDir := $(InstallEtcDir)/intensity
InstallVarDir := $(InstallDir)/var
InstallInitDir := $(InstallDir)/etc/init.d
RcFile := $(InstallDir)/rc
ONSRoot := 127.0.0.1:9880
ONSPort := 127.0.0.1:9881
CDBDPort := 127.0.0.1:9882
ONSRootOfStage1 := 127.0.0.1:9883
ONSPortOfStage1 := 127.0.0.1:9884
CDBDPortOfStage1 := 127.0.0.1:9885
Lib := $(Root)/build/libo.a
ScriptDir := $(Root)/build/scripts
BINARIES = cdbd nsh obci obco obdeps obload obtofgen obzap pons onsstat onsshut onsmkdir onswait
InstalledBinaries := $(patsubst %,$(InstallBinDir)/%,$(BINARIES))
InitScripts := cdbd pons
InstalledInitScripts := $(patsubst %,$(InstallInitDir)/%,$(InitScripts))
InsertableInitScripts := $(patsubst %,$(InitDir)/%,$(InitScripts))
MakeParams := DestDir=$(DestDir) BinDir=$(BinDir) DBAuth=$(DBAuth) \
	ONSRoot=$(ONSRoot) PonsDir=$(PonsDir) CDBDDir=$(CDBDDir) \
	CDBDir=$(CDBDir) SrcDir=$(SrcDir) IntensityDir=$(IntensityDir) \
	InstallDir=$(InstallDir) InstallBinDir=$(InstallBinDir) \
	InstallDBDir=$(InstallDBDir) InstallPonsDir=$(InstallPonsDir) \
	InstallIntensityDir=$(InstallIntensityDir) ONSPort=$(ONSPort) \
	CDBDPort=$(CDBDPort)
Stage1Dir := $(Root)/stage1
Stage2Dir := $(Root)/stage2
TOF_MODULES = \
    Coroutines Process RTErrors Storage SysArgs SysInterrupts SysModules SysSegments \
    CDBDaemon NamesShell OberonCheckIn OberonCompiler OberonDependencies OberonLoader \
    OberonI386TransportableObjectFormatGenerator OberonZap PersistentNameServer \
    NodeStatus ShutdownNode MakeDirectory PathWaiter
# Mapping of binary names to module names
MODULES_cdbd = CDBDaemon
MODULES_nsh = NamesShell
MODULES_obci = OberonCheckIn
MODULES_obco = OberonCompiler
MODULES_obdeps = OberonDependencies
MODULES_obload = OberonLoader
MODULES_obtofgen = OberonI386TransportableObjectFormatGenerator
MODULES_obzap = OberonZap
MODULES_pons = PersistentNameServer
MODULES_onsstat = NodeStatus
MODULES_onsshut = ShutdownNode
MODULES_onsmkdir = MakeDirectory
MODULES_onswait = PathWaiter

# Function to get the module name from the binary name
get_module = $(if $(MODULES_$(1)),$(MODULES_$(1)),$(1))

# Directories for TOF and object files
TOFDIR := tofs
OBJDIR := build/objs

# Tools
TOF2ELF := $(ScriptDir)/tof2elf
AR := ar
RANLIB := ranlib

# List of TOF modules (without the .tof extension)
TOF_MODULES := $(basename $(notdir $(wildcard $(TOFDIR)/*.tof)))

# Generate object file paths
OBJS := $(addprefix $(OBJDIR)/, $(addsuffix .o, $(TOF_MODULES)))

.PHONY: all
all: installbin installman installsrc installvar installetc installrc

.PHONY: install
install: all

.PHONY: bindir
bindir:
	mkdir -p $(InstallBinDir)

.PHONY: installbin
installbin: bindir $(InstalledBinaries) installutil

# Build binaries
$(InstallBinDir)/%: scripts $(Lib)
	$(ScriptDir)/oblink $@ $(Lib) $(call get_module,$*)

# Update scripts target
.PHONY: scripts
scripts:
	cd src/util && $(MAKE) $(MakeParams) \
	InstallDir=$(Root) \
	InstallBinDir=$(ScriptDir) \
	DestDir=$(Root) \
	BinDir=$(ScriptDir) \
	IntensityDir=$(IntensityDir) \
	install

.PHONY: installutil
installutil:
	cd src/util && $(MAKE) $(MakeParams) DestDir=$(InstallDir) BinDir=$(InstallBinDir) install

# Build libo.a from object files
$(Lib): scripts $(OBJS)
	$(AR) rcs $@ $(OBJS)
	$(RANLIB) $@

# Rule to build object files from .tof files
$(OBJDIR)/%.o: $(TOFDIR)/%.tof | $(OBJDIR)
	$(TOF2ELF) -o $@ $<

# Create OBJDIR if it doesn't exist
$(OBJDIR):
	mkdir -p $(OBJDIR)

# Remove the TOF2ELF rule or adjust it
# Since tof2elf is built via scripts, you can remove this rule
# $(TOF2ELF): src/util/tof2elf/tof2elf.c
#   cd src/util/tof2elf && \
#   gcc -Wall -Wextra -g -o tof2elf tof2elf.c -lelf && \
#   cp tof2elf $(TOF2ELF)

.PHONY: installman
installman: mandir
ifneq ($(InstallManDir),$(Root)/man)
	cp -a $(Root)/man/* $(InstallManDir)
endif

.PHONY: mandir
mandir:
	mkdir -p $(InstallManDir)


.PHONY: installsrc
installsrc: srcdir
ifneq ($(InstallSrcDir),$(Root)/src)
	cp -a $(Root)/src/* $(InstallSrcDir)
endif

.PHONY: srcdir
srcdir:
	mkdir -p $(InstallSrcDir)

.PHONY: installvar
installvar:
	mkdir -p $(PonsDir)
	mkdir -p $(CDBDDir)

.PHONY: installetc
installetc: gcintensity

.PHONY: gcintensity
gcintensity:
	mkdir -p $(InstallIntensityDir)
	$(ScriptDir)/obgcdflts $(InstallIntensityDir)

.PHONY: installrc
installrc: $(RcFile)

$(RcFile):
	echo OBERON=$(DestDir) >$@
	echo PATH=$(BinDir):\$$PATH >>$@
	echo MANPATH=$(ManDir):\$$MANPATH >>$@
	echo ONS_ROOT=$(ONSRoot) >>$@
	echo ONS_PORT=$(ONSPort) >>$@
	echo CDBD_PORT=$(CDBDPort) >>$@
	echo CDB_BASEDIR=$(CDBDir) >>$@
	echo CDB_AUTH=$(DBAuth) >>$@
	echo export OBERON PATH MANPATH ONS_ROOT ONS_PORT \
	   CDBD_PORT CDB_BASEDIR CDB_AUTH >>$@

.PHONY: clean
clean:
	rm -rf $(OBJDIR) $(Lib) $(InstalledBinaries)

# Phony targets
.PHONY: all install installbin bindir scripts installman mandir \
	installsrc srcdir installvar installetc gcintensity installrc clean

