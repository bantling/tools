# The version of Alpine to use in the Docker image.
FROM archlinux AS compile

# Lots of cross-compiler guides include instructions for compiling MPC, MPFR,
# and GMP. Don't: these are dependencies required for compiling GCC itself, and
# do not affect the compiled output. Per GCC's own documented recommendation
# (https://gcc.gnu.org/wiki/InstallingGCC), we'll use the libraries provided by
# our distro package manager.
RUN pacman --noconfirm -S base-devel

# The FreeBSD version to target for cross-compilation.
ARG FBSD_VERSION=13.0
# The mirror from which to retrieve FreeBSD archives. It may be easier to
# override this mirror than to use an HTTP proxy (e.g., to speed up local
# development or reduce bandwidth consumption).
ARG FBSD_MIRROR=http://ftp-archive.freebsd.org/pub/FreeBSD/releases
ARG FBSD_AMD64_BASE_URL=${FBSD_MIRROR}/amd64/${FBSD_VERSION}-RELEASE/base.txz
ARG FBSD_I386_BASE_URL=${FBSD_MIRROR}/i386/${FBSD_VERSION}-RELEASE/base.txz

# The mirror from which to retrieve GNU sources.
ARG GNU_MIRROR=https://ftp.gnu.org/gnu
# FreeBSD 13.0 includes GCC 11.2.0
# We want to keep the compiler version pretty close to that included
# with the distro so we retain compatibility with the original libgcc.
ARG GCC_URL=${GNU_MIRROR}/gcc/gcc-11.2.0/gcc-11.2.0.tar.xz
# Per https://wiki.osdev.org/Cross-Compiler_Successful_Builds, binutils
# versions other than 2.37 are uncharted territory with GCC 11.2.0.
ARG BINUTILS_URL=${GNU_MIRROR}/binutils/binutils-2.37.tar.xz

ARG MAKEFLAGS="-j 4"

ADD $FBSD_AMD64_BASE_URL /usr/local/src/fbsd-amd64-base.txz
ADD $FBSD_I386_BASE_URL /usr/local/src/fbsd-i386-base.txz
ADD $GCC_URL $BINUTILS_URL /usr/local/src/
COPY compile .

RUN export FBSD_MAJOR=$(echo $FBSD_VERSION | cut -d '.' -f 1) \
    && /usr/local/src/build-cross x86_64-freebsd$FBSD_MAJOR \
                                  /usr/local/src/fbsd-amd64-base.txz \
    && /usr/local/src/build-cross i386-freebsd$FBSD_MAJOR \
                                  /usr/local/src/fbsd-i386-base.txz
RUN rm -Rf /usr/local/src

FROM archlinux AS deploy

RUN pacman -S file make

COPY --from=compile \
     /usr/local/ \
     /usr/local/
COPY deploy .
COPY README.md .
WORKDIR /workdir
