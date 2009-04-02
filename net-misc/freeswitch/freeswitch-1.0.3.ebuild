#
# Copyright (C) 2008 Stefan Knoblich <s.knoblich@axsentis.de>
#
# Distributed under the terms of the GNU General Public License 2
# see http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt for
# more information
#

EAPI="1"

inherit subversion autotools flag-o-matic

DESCRIPTION="FreeSWITCH telephony platform SVN Trunk"
HOMEPAGE="http://www.freeswitch.org/"

if [ "${PN}" = "freeswitch-svn" ]; then
	ESVN_REPO_URI="http://svn.freeswitch.org/svn/freeswitch/trunk"
	ESVN_PROJECT="freeswitch"
	ESVN_BOOTSTRAP="bootstrap.sh"
else
	SRC_URI="http://files.freeswitch.org/${P}.tar.bz2"
fi

LICENSE="MPL-1.1"
KEYWORDS="~amd64 ~x86"
SLOT="0"

IUSE="debug +libedit nosamples odbc +resampler sctp"

IUSE_MODULES="alsa amr +cdr_csv celt cepstral +console dialplan_asterisk dialplan_directory
easyroute fax flite +g723_1 g729 h26x iax +ilbc java dingaling lcr +local_stream +logfile +lua
managed opal openzap perl pocketsphinx portaudio python radius_cdr
say_de +say_en say_es say_fr say_it say_nl say_zh shout siren +sndfile +sofia +speex
spidermonkey spidermonkey_curl spidermonkey_core_db spidermonkey_odbc spidermonkey_socket spidermonkey_teletone
+syslog +tone_stream vmd +voipcodecs xml_cdr xml_curl xml_ldap xml_rpc yaml zeroconf"

# inter-module dependencies
INTER_MODULE_DEPENDS="
	spidermonkey_socket:spidermonkey
	spidermonkey_teletone:spidermonkey
	spidermonkey_core_db:spidermonkey
	spidermonkey_curl:spidermonkey
	spidermonkey_odbc:spidermonkey
"

# modules need these core functions
CORE_MODULE_DEPENDS="
	easyroute:odbc
	lcr:odbc
"

# external dependencies of modules
MODULES_RDEPEND="
	freeswitch_modules_fax?  ( media-libs/tiff )
	freeswitch_modules_alsa? ( media-libs/alsa-lib )
	freeswitch_modules_radius_cdr? ( net-dialup/freeradius-client )
	freeswitch_modules_xml_curl? ( net-misc/curl )
	freeswitch_modules_xml_ldap? ( net-nds/openldap )
	freeswitch_modules_ldap? ( net-nds/openldap )
	freeswitch_modules_java? ( >=virtual/jdk-1.5 )
	freeswitch_modules_opal? ( =net-libs/opal-9999
				   =dev-libs/ptlib-9999 )
	freeswitch_modules_spidermonkey_curl? ( net-misc/curl )
	freeswitch_modules_spidermonkey_odbc? ( dev-db/unixODBC )
	freeswitch_modules_python? ( >=dev-lang/python-2.4 )
	freeswitch_modules_managed? ( >=dev-lang/mono-1.9 )
	freeswitch_modules_easyroute? ( dev-db/unixODBC )
	freeswitch_modules_lcr? ( dev-db/unixODBC )
"

# external core dependencies
CORE_RDEPEND="
	 odbc? ( dev-db/unixODBC )
"

#
#
#
RDEPEND="virtual/libc
	 !net-misc/freeswitch
	 ${CORE_RDEPEND}
	 ${MODULES_RDEPEND}"

DEPEND="${RDEPEND}
	>=sys-devel/autoconf-2.60
	>=sys-devel/automake-1.10
	sctp? ( kernel_linux? ( net-misc/lksctp-tools ) )"

PDEPEND=">=net-misc/freeswitch-sounds-1.0.7
	 >=net-misc/freeswitch-music-1.0.7"

#
#
#
for mod in ${IUSE_MODULES}; do
	IUSE="${IUSE} "${mod//[^+]/}freeswitch_modules_${mod/+}""
done


pkg_setup() {
	local x mod dep error_cnt=0 mod_cnt=0

	ewarn "--- Work-In-Progress ebuild ---"
	epause 5

	#
	# 1. safety check
	#
	for mod in ${IUSE_MODULES}; do
		use freeswitch_modules_${mod/+} && (( mod_cnt++ ))
	done
	if [ "${mod_cnt}" = "0" -a "${FREESWITCH_CORE_ONLY}" != "yes" ]; then
		eerror "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		eerror "No modules selected for build! Are you sure you only want the FreeSWITCH core?"
		eerror "This isn't a good idea, usually..."
		eerror ""
		eerror "If you really know what you are doing set FREESWITCH_CORE_ONLY="yes" in your make.conf"
		eerror "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		die "FREESWITCH_MODULES empty / no modules selected for build"
	fi

	#
	# 2. check prerequisites
	#
	if use freeswitch_modules_cepstral; then

		SWIFT_HOME="${SWIFT_HOME:-/opt/swift}"

		if [ ! -d "${SWIFT_HOME}" ]; then
			eerror "No cepstral installation found in \"${SWIFT_HOME}\""
			die "No cepstral installation found in \"${SWIFT_HOME}\""
		fi

		if [ ! -e "${SWIFT_HOME}/lib/libswift.so" ]; then
			eerror "Cepstral library not found in \"${SWIFT_HOME}\""
			die "Cepstral library not found!"
		fi

		einfo "Cepstral installation found in \"${SWIFT_HOME}\""

		export SWIFT_HOME
	fi

	if use freeswitch_modules_python ; then

		if built_with_use --missing false dev-lang/python nothreads ; then
			echo
			eerror "python: FreeSWITCH needs python with threads support"
			eerror "python: please reemerge python with \"nothreads\" useflag disabled"
			echo
			(( error_cnt++ ))

		elif ! built_with_use --missing true dev-lang/python threads ; then
			echo
			eerror "python: FreeSWITCH needs python with threads support"
			eerror "python: please reemerge python with \"threads\" useflag enabled"
			echo
			(( error_cnt++ ))
		fi
	fi

	if use freeswitch_modules_perl && ! built_with_use dev-lang/perl ithreads; then
		echo
		eerror "perl: FreeSWITCH needs perl with threads support"
		eerror "perl: please reemerge libperl and perl with \"ithreads\" useflag enabled"
		echo

		(( error_cnt++ ))
	fi

	if use freeswitch_modules_xml_ldap && ! built_with_use net-nds/openldap sasl; then
		echo
		eerror "ldap: OpenLDAP with sasl support is required"
		eerror "ldap: please reemerge openldap with \"sasl\" useflag enabled"
		echo

		(( error_cnt++ ))
	fi

	if [ "${error_cnt}" != "0" ]; then
		echo
		eerror "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		eerror "Build-time requirements not met!"
		eerror "Please correct above error messages or disable the useflags and re-emerge ${PN}"
		eerror "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		die "Build-time requirements not met: ${error_cnt} errors"
	fi

	#
	# 3. check inter-module dependencies
	#
	einfo "Checking inter-module dependencies..."
	for x in ${INTER_MODULE_DEPENDS}; do
		mod="${x%:*}"
		dep="${x#*:}"

		if use "freeswitch_modules_${mod}" && ! use "freeswitch_modules_${dep}"; then
			# check if this module has an external dependency
			if $(echo "${MODULES_RDEPEND}" | grep -q "freeswitch_modules_${dep}\?"); then
				eerror "Module \"${mod}\" requires module \"${dep}\","
				eerror "can not auto-enable this feature because it has an unmet external dependency!"
				(( error_cnt++ ))
			else
				ewarn "Module \"${mod}\" requires module \"${dep}\" to be enabled, auto-enabling!"
				FREESWITCH_AUTO_USE="${FREESWITCH_AUTO_USE} freeswitch_modules_${dep}"
			fi
		fi
	done

	#
	# 4. check core dependencies
	#
	einfo "Checking core dependencies..."
	for x in ${CORE_MODULE_DEPENDS}; do
		mod="${x%:*}"
		dep="${x#*:}"

		if hasq "freeswitch_modules_${mod}" ${FREESWITCH_AUTO_USE} ${USE} && ! use "${dep}"; then
			# check if this core option has an external dependency
			if $(echo "${CORE_RDEPEND}" | grep -q "${dep}\?"); then
				eerror "Module \"${mod}\" requires core useflag \"${dep}\","
				eerror "can not auto-enable this feature because it has an unmet external dependency!"
				(( error_cnt++ ))
			else
				ewarn "Module \"${mod}\" requires core useflag \"${dep}\", auto-enabling!"
				FREESWITCH_AUTO_USE="${FREESWITCH_AUTO_USE} ${dep}"
			fi
		fi
	done

	if [ "${error_cnt}" != "0" ]; then
		echo
		eerror "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		eerror "Inter-module and/or module-core dependencies not met and auto-enabling failed because of unmet"
		eerror "external dependencies! This is for your own security, sorry..."
		eerror "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		die "Please read the error messages above and fix the listed issues"
	fi

	export FREESWITCH_AUTO_USE="${FREESWITCH_AUTO_USE}"


	#
	# 4. create user + group
	#
	enewgroup freeswitch
	enewuser freeswitch -1 -1 /opt/freeswitch freeswitch
}

fs_abi_generate_symbols_array() {
	local libfile="$1" syms

	if [ ! -f "${libfile}" ]; then
		eerror "Library ${libfile} does not exist"
		return 1
	fi

	syms="$(nm -DS -t d --defined-only "${libfile}" | sed -e 's:0\+\([1-9][0-9]*\):\1:g' | awk -v IGNORECASE=1 '/switch_.+/{ print "\tsymbols[\""$4"\"]="$2";" }')"
	if [ -z "${syms}" ]; then
		eerror "Failed to create list of exported libfreeswitch symbols"
		return 1
	fi

	echo "${syms}"
	return 0
}

fs_check_core_abi_compat() {
	local libfreeswitch libfreeswitch_syms

	if [ "${EBUILD_PHASE}" != "preinst" ]; then
		eerror "fs_check_core_abi_compat() can only be called from pkg_preinst"
		return 1
	fi

	# no need to check anything if there's no previous install...
	[ ! -e "${ROOT}"/opt/freeswitch/mod ] && return 0

	libfreeswitch="$(ls -1 "${ROOT}"/opt/freeswitch/lib/libfreeswitch.so.*.*.*)"
	if [ ! -f "${libfreeswitch}" ]; then
		eerror "Failed to locate old libfreeswitch"
		return 1
	fi

	libfreeswitch_syms="$(fs_abi_generate_symbols_array "${libfreeswitch}")"
	if [ -z "${libfreeswitch_syms}" ]; then
		eerror "Failed to create list of exported libfreeswitch symbols"
		return 1
	fi

	cat > "${T}/symbols_check_abi.awk" <<-EOF
	BEGIN{
	${libfreeswitch_syms}
	}

	/switch_.+/{
	    sym=\$4
            sym_len=\$2

	    if (! sym in symbols)
	        print sym

	    if (symbols[sym] != sym_len)
	        print sym
	}
	EOF

	libfreeswitch="$(ls -1 "${D}"/opt/freeswitch/lib/libfreeswitch.so.*.*.*)"
	if [ ! -f "${libfreeswitch}" ]; then
		eerror "Failed to locate new libfreeswitch"
		return 1
	fi

	einfo "Checking for incompatible ABI changes in FreeSWITCH core library..."
	changed_syms="$(nm -DS -t d --defined-only "${libfreeswitch}" | sed -e 's:0\+\([1-9][0-9]*\):\1:g' | awk -v IGNORECASE=1 -f "${T}/symbols_check_abi.awk")"
	if [ -n "${changed_syms}" ]; then
		einfo "Some FreeSWITCH API functions have been modified, external modules may have to be rebuild"
	fi

	export FREESWITCH_ABI_CHANGED_SYMBOLS="${changed_syms}"
}

fs_check_modules_api_compat() {
	local x mod libfreeswitch libfreeswitch_syms
	local sym need_upgrade module_syms

	if [ "${EBUILD_PHASE}" != "preinst" ]; then
		eerror "fs_check_modules_api_compat() can only be used in pkg_preinst"
		return 1
	fi

	# no need to check anything if there's no previous install...
	[ ! -e "${ROOT}"/opt/freeswitch/mod ] && return 0

	# create an awk script with the list of "switch_*" symbols exported by libfreeswitch
	# run the script once for each module, the list of needed "switch_*" symbols is supplied via stdin
	# (raw nm output)
	#
	libfreeswitch="$(ls -1 "${ROOT}"/opt/freeswitch/lib/libfreeswitch.so.*.*.*)"
	if [ ! -f "${libfreeswitch}" ]; then
		eerror "Failed to locate libfreeswitch"
		return 1
	fi

	libfreeswitch_syms="$(fs_abi_generate_symbols_array "${libfreeswitch}")"
	if [ -z "${libfreeswitch_syms}" ]; then
		eerror "Failed to create list of exported libfreeswitch symbols"
		return 1
	fi

	cat > "${T}/symbols_check.awk" <<-EOF
	BEGIN{
	${libfreeswitch_syms}
	}

	/switch_.+/{
	    sym=\$2

	    if (! sym in symbols)
	        exit 1
	}
	EOF

	einfo "Checking for incompatible modules..."
	for x in "${ROOT}"/opt/freeswitch/mod/mod_*.so; do
		mod="$(basename "${x}")"
		need_upgrade="no"

		# no need to check modules that will be overwritten
		[ -e "${D}/opt/freeswitch/mod/${mod}" ] && continue

		# check module
		module_syms="$(nm -D --undefined-only "${x}" | sed -e 's:0\+\([1-9][0-9]*\):\1:g' | awk -v IGNORECASE=1 '/switch_.+/{ print $2 }')"
		if ! $(echo "${module_syms}" | awk -v IGNORECASE=1 -f "${T}/symbols_check.awk"); then
			# needed symbol is not in the list of available ones, mark module broken
			need_upgrade="yes"
		else
			# check if one of the used functions has been modified in the core,
			# this may be an indication that the ABI has been changed too
			# NOTE: This check isn't perfect...
			for sym in ${FREESWITCH_ABI_CHANGED_SYMBOLS}; do

				if $(echo "${module_syms}" | grep -q "^${sym}"); then
					# symbol is in the list of functions that _may_ have been changed in a
					# ABI incompatible way, mark module broken
					need_upgrade="maybe"
					break
				fi
			done
		fi

		case "${need_upgrade}" in
		maybe)
			ewarn "Module \"${mod}\" uses a function that has been changed since the last version, you may need to upgrade"
			;;
		yes)
			eerror "Module \"${mod}\" is incompatible with this FreeSWITCH version, please upgrade"
			;;
		*)
			;;
		esac
	done
	return 0
}

fs_set_module() {
	local config="build/modules.conf.in"
	local mod="$2"

	[ -f "modules.conf" ] && config="modules.conf"

	case ${mod} in
	mod_openzap)
		category="../../libs/openzap"
		;;
	*)
		category="$(ls -d src/mod/*/${mod} | cut -d'/' -f3)"
		;;
	esac

	[ -z "${category}" ] && die "unable to determine category for module \"${mod}\" (from: `pwd`)"

	case $1 in
	enable)
		if grep -q "/${mod}$" ${config}
		then
			einfo "  ++ Enabling ${mod}"
			sed -i -e "/\/${mod}$/s:.*:${category}/${mod}:" \
				${config} || die "Failed to enable module \"${mod}\""
		else
			# module not in list, add it
			einfo "  **  Adding ${mod}"
			echo "${category}/${mod}" >> ${config}
		fi
		;;

	disable)
		einfo "  -- Disabling ${mod}"
		sed -i -e "/\/${mod}$/s:.*:#${category}/${mod}:" \
			${config} || die "Failed to disable module \"${mod}\""
		;;
	*)
		eerror "fs_set_module <enable|disable> <module_path>"
		return 1
		;;
	esac

	return 0
}

setup_modules() {
	local x mod enablemod

	einfo "Optional modules:"
	for x in ${IUSE_MODULES}; do
		mod="${x/+}"
		enablemod=1

		[ -z "${x}" ] && continue

		fs_use freeswitch_modules_${mod} || enablemod=0

		[ ${enablemod} -eq 1 ] \
			&& fs_set_module "enable"  "mod_${mod}" \
			|| fs_set_module "disable" "mod_${mod}"
	done
}

src_unpack() {
	if [ "${PN}" = "freeswitch-svn" ]; then
		subversion_src_unpack
	else
		unpack ${A}
	fi
	cd "${S}"

	#
	# 1. enable / disable optional modules
	#
	setup_modules

	#
	# 2. workarounds remove as soon as the fix has been comitted
	#
}

fs_use() {
	if hasq $1 ${FREESWITCH_AUTO_USE} ${USE}; then
		return 0
	fi
	return 1
}

fs_enable() {
	local option value

	if [ -z "${1}" ]; then
		eerror "fs_enable(): Usage fs_conf_enable <useflag> [<optname> [<optvalue>]]"
		return 1
	fi

	if [ -n "${3}" ]; then
		value="=${3}"
	fi

	option="${2}"
	if [ -z "${option}" ]; then
		option="${1}"
	fi

	if fs_use $1; then
		echo "--enable-${option}${value}"
	else
		echo "--disable-${option}"
	fi
}

fs_with() {
	local option value

	if [ -z "${1}" ]; then
		eerror "fs_with(): Usage fs_conf_with <useflag> [<optname> [<optvalue>]]"
		return 1
	fi

	if [ -n "${3}" ]; then
		value="=${3}"
	fi

	option="${2}"
	if [ -z "${option}" ]; then
		option="${1}"
	fi

	if hasq $1 ${FREESWITCH_AUTO_USE} ${USE}; then
		echo "--with-${option}${value}"
	else
		echo "--without-${option}"
	fi
}

fs_is_upgrade() {
	# svn install is always an upgrade
	[ "${PN/-svn}" != "${PN}" ] && return 0

	# regular up/-downgrade
	if has_version "${PN}" && ! has_version "~${P}"; then
		return 0
	fi

	# not an up-/downgrade
	return 1
}

src_compile() {
	local java_opts

	#
	# filter some flags known to break things
	#

	# breaks linking freeswitch core lib (missing libdl symbols)
	filter-ldflags -Wl,--as-needed

	# breaks openzap
	filter-flags -fvisibility-inlines-hidden


	#
	# option handling
	#
	fs_use freeswitch_modules_java && \
		java_opts="--with-java=$(/usr/bin/java-config -O)"

	#
	# 1. configure
	#
	einfo "Configuring freeswitch..."
	econf \
		-C \
		--prefix=/opt/freeswitch \
		--libdir=/opt/freeswitch/lib \
		--sysconfdir=/opt/freeswitch/conf \
		$(fs_enable sctp) \
		$(fs_with freeswitch_modules_python python) \
		$(fs_enable debug) \
		$(fs_enable resampler resample) \
		$(fs_enable odbc core-odbc-support) \
		$(fs_enable libedit core-libedit-support) \
		${java_opts} || die "configure failed"

	#
	# 2. build everything
	#
	einfo "Building freeswitch... (this can take a long time)"
	emake MONO_SHARED_DIR="${T}" || die "building freeswitch failed"
}


src_install() {
	#
	# 1. Install core
	#
	einfo "Installing freeswitch core and modules..."
	make install DESTDIR="${D}" MONO_SHARED_DIR="${T}" || die "Installation of freeswitch core failed"

	#
	# 2. Documentation, sample config files, ...
	#
	einfo "Installing documentation and misc files..."
	dodoc AUTHORS NEWS README ChangeLog INSTALL

	insinto /opt/freeswitch/scripts/rss
	doins scripts/rss/rss2ivr.pl

	insinto /opt/freeswitch/scripts/multicast
	doins scripts/multicast/*.pl

	dodir /opt/freeswitch/cores
	keepdir /opt/freeswitch/{htdocs,log,log/xml_cdr,db,grammar,cores}

	newinitd "${FILESDIR}"/freeswitch-1.0.3.rc6 freeswitch
	newconfd "${FILESDIR}"/freeswitch.confd     freeswitch

	# save a copy of the default config
	einfo "Saving a copy of the default configuration..."
	find "${D}/opt/freeswitch/conf" -type f | sed -e "s:${D}/opt/freeswitch::" |\
	while read fn; do
		docinto "$(dirname "${fn}")"
		dodoc   "${D}/opt/freeswitch/${fn}"
	done

	# remove sample configuration if the user wishes so,
	# but only if this isn't a fresh installation
	if use nosamples; then
		if ! has_version "net-misc/freeswitch" && ! has_version "net-misc/freeswitch-svn"; then
			einfo "No previous installation of FreeSWITCH found, installing sample configuration..."
		else
			einfo "Removing sample configuration files..."
			rm -r "${D}"/opt/freeswitch/conf/*
		fi
	fi

	# move configuration to /etc/freeswitch and
	# create symlink to /opt/freeswitch/conf
	dodir /etc
	mv "${D}/opt/freeswitch/conf" "${D}/etc/freeswitch"
	dosym /etc/freeswitch /opt/freeswitch/conf

	# keep managed subdir
	fs_use freeswitch_modules_managed && keepdir /opt/freeswitch/mod/managed

	# TODO: install contributed stuff

	#
	# 3. Remove .a and .la files
	#
	find "${D}" \( -name "*.la" -or -name "*.a" \) -exec rm -f {} \; || die "Failed to cleanup .a and .la files"

	#
	# 4. Fix permissions
	#
	einfo "Setting file and directory permissions..."

	# sysconfdir
	chown -R root:freeswitch "${D}/etc/freeswitch"
	chmod -R u=rwX,g=rX,o=   "${D}/etc/freeswitch"

	# prefix
	chown -R root:freeswitch "${D}/opt/freeswitch"
	chmod -R u=rwX,g=rX,o=   "${D}/opt/freeswitch"
	# allow read access for things like building external modules
	chmod -R u=rwx,g=rx,o=rx "${D}/opt/freeswitch/"{lib*,bin,include}
	chmod    u=rwx,g=rx,o=rx "${D}/opt/freeswitch"

	for x in db log cores; do
		chown -R freeswitch:freeswitch "${D}/opt/freeswitch/${x}"
	done
}

pkg_preinst() {
	#
	# 1. upgrade api check
	#
	if fs_is_upgrade; then
		einfo "Performing core ABI compatibility check..."

		# compare exported symbols of new and old libfreeswitch to make sure
		# external modules will still work
		fs_check_core_abi_compat

		# check if external modules will still work after upgrade
		# to new libfreeswitch
		fs_check_modules_api_compat
	fi

	#
	# 2. preserve existing config files
	#
	if use nosamples; then
		if has_version "net-misc/freeswitch" || has_version "net-misc/freeswitch-svn"; then
			einfo "Preserving existing configuration..."
			rm -r "${D}/etc/freeswitch"
			cp -dpR "${ROOT}/etc/freeswitch" "${D}/etc"
		fi
	fi
}

pkg_postinst() {
	#
	# 1. Info
	#
	echo
	einfo "FreeSWITCH has been successfully emerged!"
	echo
	einfo "More information about FreeSWITCH and how to configure it"
	einfo "can be found on one of these sites:"
	einfo
	einfo "    http://www.freeswitch.org/"
	einfo "    http://wiki.freeswitch.org/"
	echo

	einfo "A copy of the default configuration has been saved to"
	einfo "    ${ROOT}/usr/share/doc/${PF}/conf"
	echo
}

pkg_config() {
	local answer="N"

	[ "$(id -u)" != "0" ] && {
		eerror "This action needs root privileges"
		die "Can not run as non-root user"
	}

	einfo "Reset permissions to installation defaults (y/N)?"
	read answer

	if [ "${answer/y/Y}" = "Y" ]; then
		#
		# Fix permissions
		#
		einfo "Setting file and directory permissions..."

		# sysconfdir
		chown -R root:freeswitch "${ROOT}/etc/freeswitch"
		chmod -R u=rwX,g=rX,o=   "${ROOT}/etc/freeswitch"

		# prefix
		chown -R root:freeswitch "${ROOT}/opt/freeswitch"
		chmod -R u=rwX,g=rX,o=   "${ROOT}/opt/freeswitch"
		# allow read access for things like building external modules
		chmod -R u=rwx,g=rx,o=rx "${ROOT}/opt/freeswitch/"{lib*,bin,include}
		chmod    u=rwx,g=rx,o=rx "${ROOT}/opt/freeswitch"

		for x in db log cores; do
			chown -R freeswitch:freeswitch "${ROOT}/opt/freeswitch/${x}"
		done
		einfo "Done"
	else
		ewarn "Aborted"
	fi
}
