# Copyright 2014 Julian Ospald <hasufell@posteo.de>
# Distributed under the terms of the GNU General Public License v2
# $Header: $
# NOTE: This file is based on an ebuild of Julian Ospald. In so far the header may be wrong. I will correct this ASAP I got a reply redarding this topic.

EAPI=5

inherit eutils gnome2-utils multilib cmake-utils

DESCRIPTION="An open source reimplementation of TES III: Morrowind game engine. This version uses the OpenSceneGraph toolkit, which will be the only one used in the future."

HOMEPAGE="https://openmw.org/"
LICENSE="GPL-3 MIT BitstreamVera OFL-1.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc devtools"

# get the right sources
#if [[ ${PV} == *999? ]]; then
        EGIT_REPO_URI="https://github.com/scrawl/openmw.git"
        if [[ $(get_version_component_count) -ge 4 ]]; then
                EGIT_BRANCH=openmw$(get_version_component_range 2)
        fi
#else
#        SRC_URI="http://github.com/OpenMW/${PN}/archive/${P}.tar.gz"
#        S=${WORKDIR}/${PN}-${P}
#fi

# XXX static build
RDEPEND="
	app-arch/unshield
	>=dev-games/mygui-3.2.1 # [ogre] is most probably not needed anymore
	>=dev-games/openscenegraph-3.2.1[qt4,ffmpeg,jpeg,png,truetype,zlib] # check what's really needed (qt is)
	>=dev-libs/boost-1.46.0[nls,threads]
	dev-libs/tinyxml[stl]
	>=dev-qt/qtcore-4.7.0:4
	>=dev-qt/qtgui-4.7.0:4
	media-libs/freetype:2
	media-libs/libsdl2[X,video]
	media-libs/openal[qt4]
	>=sci-physics/bullet-2.80
	virtual/ffmpeg
	devtools? ( dev-qt/qtxmlpatterns:4[pch] )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? ( app-doc/doxygen media-gfx/graphviz )"

S=${WORKDIR}/${PN}-${P}

src_configure() {
	local mycmakeargs=(
		$(cmake-utils_use_build devtools BSATOOL)
		$(cmake-utils_use_build devtools ESMTOOL)
		$(cmake-utils_use_build devtools OPENCS)
		-DBUILD_UNITTESTS=OFF
		-DDATADIR="/usr/share/${PN}"
		-DICONDIR="/usr/share/icons/hicolor/256x256/apps"
		-DMORROWIND_DATA_FILES="/usr/share/${PN}/data"
		-DOPENMW_RESOURCE_FILES="/usr/share/${PN}/resources"
		-DGLOBAL_CONFIG_PATH="/etc"
		-DUSE_SYSTEM_TINYXML=ON
	)

	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile

	if use doc ; then
		emake -C "${CMAKE_BUILD_DIR}" doc
	fi
}

src_install() {
	cmake-utils_src_install
	dodoc README.md

	# about 46835 files, dodoc seems to have trouble
	if use doc ; then
		dodir "/usr/share/doc/${PF}"
		find "${CMAKE_BUILD_DIR}"/docs/Doxygen/html \
			-name '*.md5' -type f -delete
		mv "${CMAKE_BUILD_DIR}"/docs/Doxygen/html \
			"${D}/usr/share/doc/${PF}/" || die
	fi
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	gnome2_icon_cache_update

	elog "You need the original Morrowind Data files. If you haven't"
	elog "installed them yet, you can install them straight via the"
	elog "installation wizard which is the officially"
	elog "supported method (either by using the launcher or by calling"
	elog "'openmw-wizard' directly)."
}

pkg_postrm() {
	gnome2_icon_cache_update
}
