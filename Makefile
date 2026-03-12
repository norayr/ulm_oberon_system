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
Binaries := cdbd nsh obci obco obdeps obload obtofgen obzap pons onsstat \
	onsshut onsmkdir onswait
InstalledBinaries := $(patsubst %,$(InstallBinDir)/%,$(Binaries))
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

.PHONY:	install
install: ulmoinstall installsrc

.PHONY:	installsuse
installsuse: install installsuseinit

.PHONY:	runsuse
runsuse:	installsuse suserun

.PHONY:	bindir
bindir:
	mkdir -p $(InstallBinDir)

.PHONY:	installbin
installbin:	ulmo-core-tools

.PHONY:	installman
installman:	mandir
ifneq ($(InstallManDir),$(Root)/man)
	cp -a $(Root)/man/* $(InstallManDir)
endif

.PHONY:	mandir
mandir:
	mkdir -p $(InstallManDir)

.PHONY:	installsrc
installsrc:	srcdir
ifneq ($(InstallSrcDir),$(Root)/src)
	cp -a $(Root)/src/* $(InstallSrcDir)
endif

.PHONY:	srcdir
srcdir:
	mkdir -p $(InstallSrcDir)

.PHONY:	installvar
installvar:
	mkdir -p $(PonsDir)
	mkdir -p $(CDBDDir)

.PHONY:	installetc
installetc:	gcintensity

.PHONY:	installutil
installutil:	bindir
	cd src/util && $(MAKE) $(MakeParams) install

.PHONY:	scripts
scripts:
	cd src/util && $(MAKE) $(MakeParams) InstallDir=$(Root) InstallBinDir=$(Root)/build/scripts DestDir=$(Root) BinDir=$(Root)/build/scripts IntensityDir=$(IntensityDir) install

.PHONY: mkoblib
mkoblib: scripts $(Lib)
$(Lib):	installutil build/tofs.tgz
	$(ScriptDir)/mkoblib build

# Note: binary targets are now built via ulmoinstall (ulmo-based, no pons/cdbd).
# The old pons/cdbd-based rules have been replaced.  For the old DB-based build,
# use the scripts/mkoblib/oblink targets manually, or use the pons/cdbd system.

.PHONY:	installrc
installrc:	$(RcFile)
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

.PHONY:	installsuseinit initdir
installsuseinit:	initdir $(InstalledInitScripts)
initdir:
	mkdir -p $(InstallInitDir)
$(InstallInitDir)/cdbd:		scripts
	BASEDIR=$(DestDir) BINDIR=$(BinDir) \
	   $(ScriptDir)/obmk_suse_init_cdbd \
	      -c $(CDBDir) -d $(CDBDDir) -r $(ONSRoot) >$@
	chmod 755 $@
$(InstallInitDir)/pons:		$(ScriptDir)/obmk_suse_init_pons
	ONS_ROOT=$(ONSRoot) ONS_PORT=$(ONSPort) \
	   BASEDIR=$(DestDir) BINDIR=$(BinDir) \
	   $(ScriptDir)/obmk_suse_init_pons \
	      -d $(PonsDir) >$@
	chmod 755 $@

.PHONY:	gcintensity
gcintensity:
	mkdir -p $(InstallIntensityDir)
	$(ScriptDir)/obgcdflts $(InstallIntensityDir)

.PHONY:	suseinsserv
suseinsserv:	$(InsertableInitScripts) 
	insserv $(InitDir)/pons
	insserv $(InitDir)/cdbd
.PHONY:	suserun
suserun:	suseinsserv
	sh $(InitDir)/pons start
	sh $(InitDir)/cdbd start
.PHONY:	stdsuserun
stdsuserun:
	$(MAKE) $(MakeParams) \
	   InitDir=/etc/init.d \
	   InstallInitDir=/etc/init.d \
	   suserun

.PHONY:	stage1 runstage1 stage2 stage12cmp steadystatetest finishstage1
stage1:
	$(SHELL) -c 'time $(BinDir)/mk_obstage \
	   $(Stage1Dir) $(BinDir) $(BinDir) $(ONSRoot) $(CDBDir) $(DBAuth)'
runstage1:
	$(BinDir)/run_obstage $(Stage1Dir) $(BinDir) \
	   $(ONSRootOfStage1) $(ONSPortOfStage1) $(CDBDPortOfStage1)
stage2:
	$(SHELL) -c 'time $(BinDir)/mk_obstage \
	   $(Stage2Dir) $(BinDir) $(Stage1Dir) $(ONSRootOfStage1) \
	   $(CDBDir) $(Stage1Dir)/var/cdbd/write'
finishstage1:
	-ONS_ROOT=$(ONSRootOfStage1) \
	   $(Stage1Dir)/onsshut -a $(Stage1Dir)/var/pons/shutdown /pub/pons
stage12cmp:
	cmp $(Stage1Dir)/cdbd $(Stage2Dir)/cdbd
	cmp $(Stage1Dir)/nsh $(Stage2Dir)/nsh
	cmp $(Stage1Dir)/obci $(Stage2Dir)/obci
	cmp $(Stage1Dir)/obco $(Stage2Dir)/obco
	cmp $(Stage1Dir)/obdeps $(Stage2Dir)/obdeps
	cmp $(Stage1Dir)/obload $(Stage2Dir)/obload
	cmp $(Stage1Dir)/obtofgen $(Stage2Dir)/obtofgen
	cmp $(Stage1Dir)/obzap $(Stage2Dir)/obzap
	cmp $(Stage1Dir)/pons $(Stage2Dir)/pons
	cmp $(Stage1Dir)/onsstat $(Stage2Dir)/onsstat
	cmp $(Stage1Dir)/onsshut $(Stage2Dir)/onsshut
	cmp $(Stage1Dir)/onsmkdir $(Stage2Dir)/onsmkdir
	cmp $(Stage1Dir)/onswait $(Stage2Dir)/onswait
steadystatetest:	stage1 runstage1 stage2 finishstage1 stage12cmp

.PHONY:	download_tof2elf
download_tof2elf:
	wget -O src/util/tof2elf/tof2elf ftp://ftp.mathematik.uni-ulm.de/pub/soft/oberon/ulm/i386/tof2elf
	chmod 755 src/util/tof2elf/tof2elf
	touch src/util/tof2elf/tof2elf

# ============================================================
# ulmoinstall: DB-free build and install — no pons/cdbd needed
#
# Bootstrap binaries (bootstrap/ulmoc, bootstrap/obtofgen) seed the
# build.  Everything is then compiled from source and the bootstrap copies
# are replaced by freshly-built binaries.
#
# Usage:
#   make ulmoinstall [DestDir=/path/to/install]
# ============================================================

LibDir          := $(BinDir)/../lib
BootstrapDir    := $(Root)/bootstrap
OberonSrcDir    := $(Root)/src/oberon
UlmoUtilDir     := $(Root)/src/util/ulmo

# -- Directories ----------------------------------------------
.PHONY: ulmo-dirs
ulmo-dirs:
	mkdir -p $(InstallBinDir) $(LibDir)

# -- tof2elf: the one C tool in the pipeline ------------------
$(InstallBinDir)/tof2elf: $(Root)/src/util/tof2elf/tof2elf.c | ulmo-dirs
	gcc -O2 -o $@ $< -lelf
	chmod 755 $@

# -- Script/data tools -----------------------------------------
$(InstallBinDir)/genobrts: $(Root)/src/util/genobrts/genobrts.pl | ulmo-dirs
	cp $< $@
	chmod 755 $@

$(InstallBinDir)/oblink: $(Root)/src/util/oblink/oblink.sh | ulmo-dirs
	$(Root)/substparams BINDIR=$(BinDir) <$< >$@
	chmod 755 $@

$(InstallBinDir)/oberon-i386.ld: $(Root)/src/util/oblink/oberon-i386.ld | ulmo-dirs
	cp $< $@

$(InstallBinDir)/ulmo: $(UlmoUtilDir)/ulmo.sh | ulmo-dirs
	$(Root)/substparams BINDIR=$(BinDir) <$< >$@
	chmod 755 $@

# -- libo.a: compile all library sources ----------------------
# Bootstrap: if ulmoc / obtofgen are not yet in BinDir, copy from bootstrap/.
# The from-source builds (obtofgen and ulmoc targets below) will overwrite
# these bootstrap copies with freshly-compiled binaries afterwards.
$(LibDir)/libo.a: $(BootstrapDir)/ulmoc \
                  $(BootstrapDir)/obtofgen \
                  $(InstallBinDir)/tof2elf \
                  $(InstallBinDir)/ulmo \
                  $(wildcard $(OberonSrcDir)/*.om) \
                  | ulmo-dirs
	@if [ ! -f $(InstallBinDir)/ulmoc ]; then \
	   echo "bootstrap: installing ulmoc from bootstrap/"; \
	   cp -f $(BootstrapDir)/ulmoc $(InstallBinDir)/ulmoc; \
	   chmod 755 $(InstallBinDir)/ulmoc; \
	fi
	@if [ ! -f $(InstallBinDir)/obtofgen ]; then \
	   echo "bootstrap: installing obtofgen from bootstrap/"; \
	   cp -f $(BootstrapDir)/obtofgen $(InstallBinDir)/obtofgen; \
	   chmod 755 $(InstallBinDir)/obtofgen; \
	fi
	$(UlmoUtilDir)/build-libo.sh \
	   $(InstallBinDir) $(OberonSrcDir) $(LibDir)

# -- obtofgen: build from source (replaces bootstrap copy) ----
# Module name: OberonI386TransportableObjectFormatGenerator
$(InstallBinDir)/obtofgen: $(LibDir)/libo.a \
                            $(OberonSrcDir)/OberonI386TransportableObjectFormatGenerator.om
	$(eval _TMPD := $(shell mktemp -d /tmp/ulmoctofgen-XXXXXX))
	cd $(_TMPD) && $(InstallBinDir)/ulmo \
	   -I $(OberonSrcDir) \
	   -m OberonI386TransportableObjectFormatGenerator \
	   -L $(LibDir) \
	   $(OberonSrcDir)/OberonI386TransportableObjectFormatGenerator.om && \
	mv OberonI386TransportableObjectFormatGenerator $(InstallBinDir)/obtofgen
	rm -rf $(_TMPD)
	chmod 755 $(InstallBinDir)/obtofgen

# -- ulmoc: build from source, self-hosting -----------------
$(InstallBinDir)/ulmoc: $(LibDir)/libo.a \
                           $(InstallBinDir)/obtofgen \
                           $(OberonSrcDir)/FilesystemDB.om \
                           $(UlmoUtilDir)/Ulmo.om
	$(eval _TMPD := $(shell mktemp -d /tmp/ulmo-self-XXXXXX))
	cd $(_TMPD) && $(InstallBinDir)/ulmo \
	   -I $(OberonSrcDir) \
	   -m Ulmo \
	   -L $(LibDir) \
	   $(OberonSrcDir)/FilesystemDB.om \
	   $(UlmoUtilDir)/Ulmo.om && \
	mv Ulmo $(InstallBinDir)/ulmoc
	rm -rf $(_TMPD)
	chmod 755 $(InstallBinDir)/ulmoc

# -- DB tools: optional, built from source with ulmo ----------
# These provide the pons/cdbd infrastructure for users who want it.
# Each is an Oberon main module linked with libo.a; no DB needed to BUILD.
# Built via a phony target (loop) to avoid conflicting with the old pons/cdbd
# rules for the same target file names.
#
# Module name → binary name mapping:
#   OberonI386TransportableObjectFormatGenerator → obtofgen  (already above)
#   OberonLoader        → obload
#   CDBDaemon           → cdbd
#   PersistentNameServer→ pons
#   OberonCheckIn       → obci
#   CDBCheckoutSource   → obco
#   OberonZap           → obzap
#   OberonDependencies  → obdeps
#   NamesShell          → nsh
#   NodeStatus          → onsstat
#   ShutdownNode        → onsshut
#   MakeDirectory       → onsmkdir
#   PathWaiter          → onswait

UlmoDbTools := \
	OberonLoader:obload \
	CDBDaemon:cdbd \
	PersistentNameServer:pons \
	OberonCheckIn:obci \
	CDBCheckoutSource:obco \
	OberonZap:obzap \
	OberonDependencies:obdeps \
	NamesShell:nsh \
	NodeStatus:onsstat \
	ShutdownNode:onsshut \
	MakeDirectory:onsmkdir \
	PathWaiter:onswait

.PHONY: ulmo-db-tools
ulmo-db-tools: ulmo-core-tools
	$(foreach pair,$(UlmoDbTools), \
	  $(eval _MOD  := $(word 1,$(subst :, ,$(pair)))) \
	  $(eval _BIN  := $(word 2,$(subst :, ,$(pair)))) \
	  $(eval _DEST := $(InstallBinDir)/$(_BIN)) \
	  $(eval _TMPD := $(shell mktemp -d /tmp/ulmo-dbtool-XXXXXX)) \
	  $(shell cd $(_TMPD) && \
	      $(InstallBinDir)/ulmo \
	         -I $(OberonSrcDir) -m $(_MOD) -L $(LibDir) \
	         $(OberonSrcDir)/$(_MOD).om && \
	      mv $(_MOD) $(_DEST) && \
	      chmod 755 $(_DEST) && \
	      rm -rf $(_TMPD) && \
	      echo "  built: $(_BIN)") \
	)

# -- Top-level ulmoinstall target ------------------------------
.PHONY: ulmoinstall ulmo-core-tools
ulmo-core-tools: ulmo-dirs \
	$(InstallBinDir)/tof2elf \
	$(InstallBinDir)/genobrts \
	$(InstallBinDir)/oblink \
	$(InstallBinDir)/oberon-i386.ld \
	$(InstallBinDir)/ulmo \
	$(LibDir)/libo.a \
	$(InstallBinDir)/obtofgen \
	$(InstallBinDir)/ulmoc

ulmoinstall: ulmo-core-tools
	@echo "ulmoinstall complete."
	@echo "To also build DB tools (cdbd, pons, etc.): make ulmo-db-tools"
