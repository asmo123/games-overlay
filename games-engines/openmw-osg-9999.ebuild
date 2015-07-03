# Copyright 2014 Julian Ospald <hasufell@posteo.de>
# Distributed under the terms of the GNU General Public License v2
# $Header: $
# NOTE: This file is based on an ebuild of Julian Ospald. In so far the header may be wrong. I will correct this ASAP I got a reply redarding this topic.

EAPI=5

inherit eutils gnome2-utils multilib cmake-utils flag-o-matic versionator # check what is really needed
[[ $(get_version_component_range $(get_version_component_count)) == *999? ]] && inherit git-r3

DESCRIPTION="Open source reimplementation of TES III: Morrowind game engine. You can choose between Ogre and the new OpenSceneGraph latest version."
HOMEPAGE="https://openmw.org/"
LICENSE="GPL-3 MIT BitstreamVera OFL-1.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"
#IUSE="devtools minimal profile +tr1"
# tr1 has something to do with the "test" USE flag
# offered USE flags
IUSE="doc +launcher ogre editor +osg test"

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

# >>>>>>>>>> ogre USE flag still needed by myui?
# only needed by the game engine
OPENMW_LIBS="dev-games/mygui-3.2.1
	media-libs/openal[qt4]
	virtual/ffmpeg"				# shared lib has name *libav*
#	dev-libs/tinyxml[st1]			# not needed when OSG is used ?! RE-CHECK
#
# launcher is usually needed (for selecting plugins etc)
LAUNCHER_LIBS=">=dev-qt/qtgui-4.7 app-arch/unshield" # qtgui shared lib used, unshield used by openmw-wizard
# OpenMW Construction Set (for creating/editing mods)
OPENCS_LIBS=">=dev-qt/qtgui-4.7" # dev-qt/qtxmlpatterns[pch] not linked by any executable
# needed by all # check if nls makes sense (can't hurt anyways)
LIBDEPEND="${OPENMW_LIBS}
	>=dev-libs/boost-1.46.0[nls,threads]
	>=dev-qt/qtcore-4.7
	media-libs/freetype:2
	media-libs/libsdl2[X,video,-directfb(-)]
	>=sci-physics/bullet-2.80
	doc? ( app-doc/doxygen media-gfx/graphviz )	# check how to build this with OSG
	editor? ( ${OPENCS_LIBS} )
	launcher? ( ${LAUNCHER_LIBS} )
	ogre? >=dev-games/ogre-1.9.0-r1[boost,freeimage,opengl,threads,zip]
	osg? >=dev-games/openscenegraph-3.2.1[qt4,ffmpeg,jpeg,png,truetype,zlib]"
DEPEND="${LIBDEPEND}
	test? ( dev-cpp/gmock[tr1=] dev-cpp/gtest[tr1=] )
	virtual/pkgconfig"
[[ ${EAPI} == *-hdepend ]] || DEPEND+=" ${HDEPEND}"
RDEPEND="${LIBDEPEND}"

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
