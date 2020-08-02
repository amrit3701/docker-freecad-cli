FROM ubuntu:18.04
MAINTAINER Amritpal Singh <amrit3701@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

ENV PYTHON_VERSION 3.8.5
ENV PYTHON_MINOR_VERSION 3.8
ENV PYTHON_SUFFIX_VERSION .cpython-38
ENV PYTHON_BIN_VERSION python3.8
# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 18.0

ENV FREECAD_VERSION master
ENV FREECAD_REPO git://github.com/FreeCAD/FreeCAD.git

# python3.8-distutils https://github.com/deadsnakes/issues/issues/82
RUN \
    pack_build="git \
                python$PYTHON_MINOR_VERSION \
                python$PYTHON_MINOR_VERSION-dev \
                python$PYTHON_MINOR_VERSION-distutils \
                wget \
                build-essential \
                cmake \
                libtool \
                libboost-dev \
                libboost-date-time-dev \
                libboost-filesystem-dev \
                libboost-graph-dev \
                libboost-iostreams-dev \
                libboost-program-options-dev \
                libboost-python-dev \
                libboost-regex-dev \
                libboost-serialization-dev \
                libboost-signals-dev \
                libboost-thread-dev \
                libqt4-dev \
                libqt4-opengl-dev \
                qt4-dev-tools \
                libqtwebkit-dev \
                libocct-data-exchange-dev \
                libocct-draw-dev \
                libocct-foundation-dev \
                libocct-modeling-algorithms-dev \
                libocct-modeling-data-dev \
                libocct-ocaf-dev \
                libocct-visualization-dev \
                occt-draw \
                libeigen3-dev \
                libgts-bin \
                libgts-dev \
                libkdtree++-dev \
                libmedc-dev \
                libopencv-dev \
                libproj-dev \
                libvtk7-dev \
                libxerces-c-dev \
                libzipios++-dev \
                libode-dev \
                libfreetype6 \
                libfreetype6-dev \
                netgen-headers \
                netgen \
                libmetis-dev \
                gmsh " \
    && apt update \
    && apt install -y --no-install-recommends software-properties-common \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && add-apt-repository -y ppa:freecad-maintainers/freecad-stable \
    && apt update \
    && apt install -y --no-install-recommends $pack_build

RUN set -ex; \
    \
    wget -O get-pip.py 'https://bootstrap.pypa.io/get-pip.py'; \
    \
    python$PYTHON_MINOR_VERSION get-pip.py \
        --disable-pip-version-check \
        --no-cache-dir \
        "pip==$PYTHON_PIP_VERSION" \
    ; \
    pip --version; \
    \
    find /usr/local -depth \
        \( \
            \( -type d -a \( -name test -o -name tests \) \) \
            -o \
            \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
        \) -exec rm -rf '{}' +; \
    rm -f get-pip.py

ENV PYTHONPATH "/usr/local/lib:$PYTHONPATH"

RUN \
  # get FreeCAD Git
    cd \
    && git clone --branch "$FREECAD_VERSION" "$FREECAD_REPO" \
    && mkdir freecad-build \
    && cd freecad-build \
  # Build
    && cmake \
        -DBUILD_GUI=OFF \
        -DBUILD_QT5=OFF \
        -DPYTHON_EXECUTABLE=/usr/bin/$PYTHON_BIN_VERSION \
        -DPYTHON_INCLUDE_DIR=/usr/include/$PYTHON_BIN_VERSION \
        -DPYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/lib${PYTHON_BIN_VERSION}.so \
        -DPYTHON_BASENAME=$PYTHON_SUFFIX_VERSION \
        -DPYTHON_SUFFIX=$PYTHON_SUFFIX_VERSION \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_FEM_NETGEN=ON ../FreeCAD \
  \
    && make -j$(nproc) \
    && make install \
    && cd \
              \
              # Clean
                && rm FreeCAD/ freecad-build/ -fR

# Install GUI libraries that require to import Draft, Arch modules.
RUN pip${PYTHON_MINOR_VERSION} install PySide2
RUN pip${PYTHON_MINOR_VERSION} install six
RUN \
    ln -s \
        /usr/local/lib/python${PYTHON_MINOR_VERSION}/dist-packages/PySide2 \
        /usr/local/lib/python${PYTHON_MINOR_VERSION}/dist-packages/PySide

# This file is generated when we compile FreeCAD with GUI but right now
# while importing Draft module, Draft module is look for Draft_rc.py file.
# Bug in Draft module.
COPY Draft_rc.py /usr/local/Mod/Draft/Draft_rc.py

# Fixed bug in translate.py file.
COPY translate.py /usr/local/Mod/Draft/draftutils/translate.py

# Fixed import MeshPart module due to missing libnglib.so
# https://bugs.launchpad.net/ubuntu/+source/freecad/+bug/1866914
RUN echo "/usr/lib/x86_64-linux-gnu/netgen" >> /etc/ld.so.conf.d/x86_64-linux-gnu.conf
RUN ldconfig

# Make Python already know all FreeCAD modules / workbenches.
RUN echo "import FreeCAD\n" > /.startup.py
ENV PYTHONSTARTUP "/.startup.py"

# Clean
RUN apt-get clean \
    && rm /var/lib/apt/lists/* \
          /usr/share/doc/* \
          /usr/share/locale/* \
          /usr/share/man/* \
          /usr/share/info/* -fR
