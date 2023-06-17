# DestDir, BinDir etc are the paths that get burnt into the scripts
# InstallDir, InstallBinDir etc are the paths where we copy the files to;
# both sets are by default equal; however in case of package constructions
# we set InstallDir etc to the package construction area and DestDir etc
# to the final destination which is created later on by the package
Root := $(shell pwd)
DestDir := $(Root)
InstallDir := $(DestDir)
BinDir := $(DestDir)/bin
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
InstallPonsDir := $(InstallDir)/var/pons
InstallManDir := $(InstallDir)/man
InstallSrcDir := $(InstallDir)/src
InstallVarDir := $(InstallDir)/var
RcFile := $(InstallDir)/rc
ONSRoot := 127.0.0.1:9880
ONSRootOfStage1 := 127.0.0.1:9881
Lib := $(Root)/build/libo.a
ScriptDir := $(Root)/build/scripts
Binaries := cdbd nsh obci obco obdeps obload obtofgen obzap pons
InstalledBinaries := $(patsubst %,$(InstallBinDir)/%,$(Binaries))
MakeParams := DestDir=$(DestDir) BinDir=$(BinDir) DBAuth=$(DBAuth) \
	ONSRoot=$(ONSRoot) PonsDir=$(PonsDir) CDBDDir=$(CDBDDir) \
	CDBDir=$(CDBDir) SrcDir=$(SrcDir) \
	InstallDir=$(InstallDir) InstallBinDir=$(InstallBinDir) \
	InstallDBDir=$(InstallDBDir) InstallPonsDir=$(InstallPonsDir)
Stage1Dir := $(Root)/stage1
Stage2Dir := $(Root)/stage2

.PHONY:	install
install: installbin installman installsrc installvar installrc

.PHONY:	bindir
bindir:
	mkdir -p $(InstallBinDir)

.PHONY:	installbin
installbin:	bindir $(InstalledBinaries)

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

.PHONY:	installutil
installutil:	bindir
	cd src/util && $(MAKE) $(MakeParams) install

.PHONY:	scripts
scripts:
	cd src/util && $(MAKE) InstallDir=$(Root) InstallBinDir=$(Root)/build/scripts DestDir=$(Root) BinDir=$(Root)/build/scripts install

.PHONY: mkoblib
mkoblib: scripts $(Lib)
$(Lib):	installutil build/tofs.tgz
	$(ScriptDir)/mkoblib build

$(InstallBinDir)/obload:	scripts mkoblib
	$(ScriptDir)/oblink $@ $(Lib) OberonLoader
$(InstallBinDir)/cdbd:		scripts mkoblib
	$(ScriptDir)/oblink $@ $(Lib) CDBDaemon
$(InstallBinDir)/pons:		scripts mkoblib
	$(ScriptDir)/oblink $@ $(Lib) PersistentNameServer
$(InstallBinDir)/obtofgen:	scripts mkoblib
	$(ScriptDir)/oblink $@ $(Lib) OberonI386TransportableObjectFormatGenerator
$(InstallBinDir)/obci:		scripts mkoblib
	$(ScriptDir)/oblink $@ $(Lib) OberonCheckIn
$(InstallBinDir)/obco:		scripts mkoblib
	$(ScriptDir)/oblink $@ $(Lib) CDBCheckoutSource
$(InstallBinDir)/obzap:		scripts mkoblib
	$(ScriptDir)/oblink $@ $(Lib) OberonZap
$(InstallBinDir)/obdeps:	scripts mkoblib
	$(ScriptDir)/oblink $@ $(Lib) OberonDependencies
$(InstallBinDir)/nsh:		scripts mkoblib
	$(ScriptDir)/oblink $@ $(Lib) NamesShell

.PHONY:	installrc
installrc:	$(RcFile)
$(RcFile):
	echo OBERON=$(DestDir) >$@
	echo PATH=$(BinDir):$$PATH >>$@
	echo MANPATH=$(ManDir):$$MANPATH >>$@
	echo ONS_ROOT=$(ONSRoot) >>$@
	echo export OBERON PATH MANPATH ONS_ROOT >>$@

.PHONY:	stage1 runstage1 stage2 stage12cmp steadystatetest
stage1:
	time $(BinDir)/mk_obstage \
	   $(Stage1Dir) $(BinDir) $(BinDir) $(ONSRoot) $(CDBDir) $(DBAuth)
runstage1:
	$(BinDir)/run_obstage $(Stage1Dir) $(BinDir) $(ONSRootOfStage1)
stage2:
	time $(BinDir)/mk_obstage \
	   $(Stage2Dir) $(BinDir) $(Stage1Dir) $(ONSRootOfStage1) \
	   $(CDBDir) $(Stage1Dir)/var/cdbd/write
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
steadystatetest:	stage1 runstage1 stage2 stage12cmp
