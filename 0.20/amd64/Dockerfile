FROM ubuntu:20.04
MAINTAINER Amritpal Singh <amrit3701@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

ENV PYTHON_VERSION 3.8.5
ENV PYTHON_MINOR_VERSION 3.8
ENV PYTHON_SUFFIX_VERSION .cpython-38
ENV PYTHON_BIN_VERSION python3.8
# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 22.1

ENV FREECAD_VERSION 0.20
ENV FREECAD_REPO https://github.com/FreeCAD/FreeCAD.git

RUN \
    pack_build=" \
      git \
      python$PYTHON_MINOR_VERSION \
      python$PYTHON_MINOR_VERSION-dev \
      python$PYTHON_MINOR_VERSION-distutils \
      wget \
      build-essential \
      cmake \
      libtool \
      libboost-dev \
      lsb-release \
      libboost-date-time-dev \
      libboost-filesystem-dev \
      libboost-graph-dev \
      libboost-iostreams-dev \
      libboost-program-options-dev \
      libboost-python-dev \
      libboost-regex-dev \
      libboost-serialization-dev \
      libboost-thread-dev \
      libcoin-dev \
      libeigen3-dev \
      libgts-bin \
      libgts-dev \
      libkdtree++-dev \
      libmedc-dev \
      libocct-data-exchange-dev \
      libocct-draw-dev \
      libocct-foundation-dev \
      libocct-modeling-algorithms-dev \
      libocct-modeling-data-dev \
      libocct-ocaf-dev \
      libocct-visualization-dev \
      libopencv-dev \
      libproj-dev \
      libpyside2-dev \
      libqt5opengl5-dev \
      libqt5svg5-dev \
      libqt5webkit5-dev \
      libqt5x11extras5-dev \
      libqt5xmlpatterns5-dev \
      libshiboken2-dev \
      libspnav-dev \
      libvtk7-dev \
      libx11-dev \
      libxerces-c-dev \
      libzipios++-dev \
      pyside2-tools \
      python3-matplotlib \
      python3-pivy \
      python3-ply \
      python3-pyside2.qtcore \
      python3-pyside2.qtgui \
      python3-pyside2.qtsvg \
      python3-pyside2.qtwidgets \
      qtbase5-dev \
      qttools5-dev \
      swig \
      pyqt5-dev-tools \
      netgen-headers \
      netgen \
      libmetis-dev \
      " \
    && apt update \
    && apt install -y --no-install-recommends software-properties-common \
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
        -DBUILD_GUI=ON \
        -DBUILD_QT5=ON \
        -DPYTHON_EXECUTABLE=/usr/bin/$PYTHON_BIN_VERSION \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_FEM_NETGEN=ON ../FreeCAD \
  \
    && make -j$(nproc) \
    && make install \
    && cd \
              \
              # Clean
                && rm FreeCAD/ freecad-build/ -fR

# Fixed import MeshPart module due to missing libnglib.so
# https://bugs.launchpad.net/ubuntu/+source/freecad/+bug/1866914
RUN echo "/usr/lib/x86_64-linux-gnu/netgen" >> /etc/ld.so.conf.d/x86_64-linux-gnu.conf
RUN ldconfig

# Make Python already know all FreeCAD modules / workbenches.
ENV FREECAD_STARTUP_FILE /.startup.py
RUN echo "import FreeCAD" > ${FREECAD_STARTUP_FILE}
ENV PYTHONSTARTUP ${FREECAD_STARTUP_FILE}

# Clean
RUN apt-get clean \
    && rm /var/lib/apt/lists/* \
          /usr/share/doc/* \
          /usr/share/locale/* \
          /usr/share/man/* \
          /usr/share/info/* -fR
