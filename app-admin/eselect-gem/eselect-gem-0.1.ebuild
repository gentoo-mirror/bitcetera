# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-admin/eselect-rails/eselect-rails-0.15.ebuild,v 1.1 2009/03/17 06:26:07 graaff Exp $

DESCRIPTION="Manages symlinks for gem binaries in a generic way."
HOMEPAGE="http://www.gentoo.org/"
SRC_URI="mirror://gentoo/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND=">=app-admin/eselect-1.0.10"

src_install() {
	insinto /usr/share/eselect/modules
	doins *.eselect || die "doins failed"
}
