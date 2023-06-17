inherit eutils

DESCRIPTION="Ulm's Oberon-System for Linux/I386"
HOMEPAGE="http://www.mathematik.uni-ulm.de/sai/ss05/ai2/ulm-oberon-i386/"
SRC_URI="ftp://ftp.mathematik.uni-ulm.de/pub/soft/oberon/ulm/i386/${P}.tar.gz"
LICENSE="GPL2"
KEYWORDS="x86"
SLOT="0"
S=${WORKDIR}/${P}
DEPEND="dev-libs/libelf dev-lang/perl"
PREFIX="/usr/local/oberon"

pkg_setup() {
	if [ -f /var/lib/init.d/started/cdbd ] || [ -f /var/lib/init.d/started/pons ] ; then
	    echo
		eerror "You have to stop CDBD and PONS Services first by executing"
		eerror "   /etc/init.d/pons stop"
		die "Services still running."
	fi

	if has_version "<dev-lang/${P}"; then
	   echo
	   ewarn "Previous installation of Ulm's Oberon-System detected."
	   ewarn "If you do not delete the old database files of pons and cdbd in the specific"
	   ewarn "directories within \$OBERON/var, they will persist after upgrading."
	   ewarn "If you run load_libsources, the new library sources will be available beside"
	   ewarn "the old ones and your previously inserted sources, whereas the new sources"
	   ewarn "will be used automatically"
	   echo
	   ewarn "If you want to cancel the installation, hit CTRL+C now."
	   ewarn "Waiting 15 seconds before continuing."
	   echo
	   sleep 15
	fi   
	# create oberon group and cdbd, pons users
	enewgroup oberon
	enewuser cdbd -1 /bin/false ${PREFIX}/var/cdbd oberon
	enewuser pons -1 /bin/false ${PREFIX}/var/pons oberon
}

src_unpack() {
    unpack ${A} || die "failed to unpack"
    cd ${S} || die "failed to change into source directory"
    epatch ${FILESDIR}/Makefile.diff || die "failed to apply patch to Makefile"
}

src_compile() {
	echo "Nothing to do here" > /dev/null
}

src_install() {
	make DestDir=${PREFIX} InstallDir=${D}/${PREFIX} TempDir=${T} installgentoo || die "make install failed"
	doenvd ${T}/80oberon || die "failed to install rc file"
	newconfd ${T}/cdbd.conf cdbd || die "failed to install configuration file for cdbd service"
	newconfd ${T}/pons.conf pons || die "failed to install configuration file for pons service"
	newinitd ${FILESDIR}/cdbd.init cdbd || die "failed to install cdbd init script"
	newinitd ${FILESDIR}/pons.init pons || die "failed to install pons init script"
	touch ${D}/${PREFIX}/var/cdbd/cdbd.LOG
	touch ${D}/${PREFIX}/var/pons/pons.LOG
	# change permissions
	chown -R cdbd:oberon ${D}/${PREFIX}/var/cdbd
	chown -R pons:oberon ${D}/${PREFIX}/var/pons
	keepdir ${PREFIX}/var/cdbd
	keepdir ${PREFIX}/var/pons
}

pkg_postinst() {
	einfo "Ulm's Oberon-System sucessfully installed to /usr/local/oberon/"
	einfo "In order to update your environment variables execute"
	einfo "   source /etc/profile"
	einfo "Services are started by"
	einfo "   /etc/init.d/pons start"
	einfo "   /etc/init.d/cdbd start"
	einfo "Afterwards you have to run (only needed once)"
	einfo "   load_libsources"
}
