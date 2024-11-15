TERMUX_PKG_HOMEPAGE=https://www.mesa3d.org
TERMUX_PKG_DESCRIPTION="Mesa Panfrost Driver Based on Panfork-G610"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_LICENSE_FILE="docs/license.rst"
TERMUX_PKG_MAINTAINER="@joaobatista070"
TERMUX_PKG_VERSION="23.0.0"
TERMUX_PKG_SRCURL=https://github.com/joaobatista070/mesa-Panfork-android/archive/refs/tags/${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=bae2eb00b19f3fe3401ad9b8eea8c8ded39b4fb618af70111a721e66e04f36d7
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_DEPENDS="libandroid-shmem, libc++, libdrm, libglvnd, libwayland, libx11, libxext, libxfixes, libxshmfence, libxxf86vm, ncurses, vulkan-loader, zlib, zstd"
TERMUX_PKG_SUGGESTS="mesa-dev"
TERMUX_PKG_BUILD_DEPENDS="libllvm-static, libwayland-protocols, libxrandr, llvm, llvm-tools, mlir, xorgproto"

TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--cmake-prefix-path $TERMUX_PREFIX
-Dcpp_rtti=false
-Dgbm=enabled
-Dopengl=true
-Degl=enabled
-Degl-native-platform=x11
-Dgles1=disabled
-Dgles2=enabled
-Ddri3=enabled
-Dglx=dri
-Dllvm=disabled
-Dshared-llvm=disabled
-Dplatforms=x11,wayland
-Dgallium-drivers=panfrost,swrast
-Dosmesa=false
-Dglvnd=true
-Dxmlconfig=disabled
"

termux_step_post_get_source() {
	# Do not use meson wrap projects
	rm -rf subprojects
}

termux_step_pre_configure() {
	termux_setup_cmake

	CPPFLAGS+=" -D__USE_GNU"
	LDFLAGS+=" -landroid-shmem"

	_WRAPPER_BIN=$TERMUX_PKG_BUILDDIR/_wrapper/bin
	mkdir -p $_WRAPPER_BIN
	if [ "$TERMUX_ON_DEVICE_BUILD" = "false" ]; then
		sed 's|@CMAKE@|'"$(command -v cmake)"'|g' \
			$TERMUX_PKG_BUILDER_DIR/cmake-wrapper.in \
			> $_WRAPPER_BIN/cmake
		chmod 0700 $_WRAPPER_BIN/cmake
		sed "s|^export PKG_CONFIG_LIBDIR=|export PKG_CONFIG_LIBDIR=${TERMUX_PREFIX}/opt/libwayland/cross/lib/x86_64-linux-gnu/pkgconfig:|" \
			"${TERMUX_STANDALONE_TOOLCHAIN}/bin/pkg-config" \
			> "${_WRAPPER_BIN}/pkg-config"
		chmod +x "${_WRAPPER_BIN}/pkg-config"
		export PKG_CONFIG="${_WRAPPER_BIN}/pkg-config"
		export LLVM_CONFIG="$TERMUX_PREFIX/bin/llvm-config"
	fi
	export PATH="$_WRAPPER_BIN:$PATH"
}

termux_step_post_configure() {
	rm -f $_WRAPPER_BIN/cmake
}

termux_step_post_make_install() {
	# Avoid hard links
	local f1
	for f1 in $TERMUX_PREFIX/lib/dri/*; do
		if [ ! -f "${f1}" ]; then
			continue
		fi
		local f2
		for f2 in $TERMUX_PREFIX/lib/dri/*; do
			if [ -f "${f2}" ] && [ "${f1}" != "${f2}" ]; then
				local s1=$(stat -c "%i" "${f1}")
				local s2=$(stat -c "%i" "${f2}")
				if [ "${s1}" = "${s2}" ]; then
					ln -sfr "${f1}" "${f2}"
				fi
			fi
		done
	done

	# Create symlinks
	ln -sf libEGL_mesa.so ${TERMUX_PREFIX}/lib/libEGL_mesa.so.0
	ln -sf libGLX_mesa.so ${TERMUX_PREFIX}/lib/libGLX_mesa.so.0
}
