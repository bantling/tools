FROM multiarch/crossbuild

# The version of wxwidgets to use
ARG WX_VERSION=3.0.5

# Download release and extract it to /workdir/wxWidgets-${WX_VERSION}
RUN curl -L https://github.com/wxWidgets/wxWidgets/releases/download/v${WX_VERSION}/wxWidgets-${WX_VERSION}.tar.bz2 | \
    tar xjf -

# Update system and install needed libs
# wx won't compile without pkg-config
# Linux gtk build needs libgtk2.0-dev for --with-gtk3 option (option works with both gtk 2 and 3) 
RUN apt-get -y update && \
    apt-get -y install pkg-config libgtk2.0-dev

# Configure linux to generate a static library that supports UTF8, GTK 2
RUN mkdir -p /workdir/wxWidgets-${WX_VERSION}/build-linux && \ 
    cd /workdir/wxWidgets-${WX_VERSION}/build-linux && \
    env CROSS_TRIPLE=x86_64-linux-gnu /usr/bin/crossbuild ../configure --build=x86_64-linux --host=x86_64-linux --prefix=/usr/local/wx/linux --disable-shared --enable-utf8only --with-gtk3

# Configure windows to generate a static library that supports UTF8
RUN mkdir -p /workdir/wxWidgets-${WX_VERSION}/build-windows && \
    cd /workdir/wxWidgets-${WX_VERSION}/build-windows && \
    env CROSS_TRIPLE=x86_64-w64-mingw32 /usr/bin/crossbuild ../configure --build=x86_64-linux --host=x86_64-w64-mingw32 --prefix=/usr/local/wx/windows --disable-shared --enable-utf8only --with-msw

# Make linux build and install it
RUN cd /workdir/wxWidgets-${WX_VERSION}/build-linux; env CROSS_TRIPLE=x86_64-linux-gnu /usr/bin/crossbuild make
RUN cd /workdir/wxWidgets-${WX_VERSION}/build-linux; make install

# Make windows build and install it
RUN cd /workdir/wxWidgets-${WX_VERSION}/build-windows; env CROSS_TRIPLE=x86_64-w64-mingw32 /usr/bin/crossbuild make
RUN cd /workdir/wxWidgets-${WX_VERSION}/build-windows; make install

# Make smaller final image that does not have source and compiled objects (saves about 4GB)
FROM multiarch/crossbuild

# Just copy /usr dir, it contains /usr/local/wx, and dependencies installed via apt-get.
# This also copies lots of stuff we already have (like gcc compilers and other binaries), it's just easiest solution.
COPY --from=0 /usr /usr
