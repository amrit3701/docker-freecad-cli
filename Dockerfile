FROM ubuntu:16.04
MAINTAINER Amritpal Singh <amrit3701@gmail.com>

ENV PYTHON_VERSION 3.7.3
ENV PYTHON_MINOR_VERSION 3.7
ENV PYTHON_SUFFIX_VERSION .cpython-37m
ENV PYTHON_BIN_VERSION python3.7m
# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 18.0

ENV FREECAD_VERSION master
ENV FREECAD_REPO git://github.com/FreeCAD/FreeCAD.git


RUN \
    pack_build="git \
                python$PYTHON_MINOR_VERSION \
                python$PYTHON_MINOR_VERSION-dev \
                wget \
                build-essential \
                cmake \
                libtool \
                libxerces-c-dev \
                libboost-dev \
                libboost-filesystem-dev \
                libboost-regex-dev \
                libboost-program-options-dev \
                libboost-signals-dev \
                libboost-thread-dev \
                libboost-python-dev \
                libqt4-dev \
                libqt4-opengl-dev \
                qt4-dev-tools \
                liboce-modeling-dev \
                liboce-visualization-dev \
                liboce-foundation-dev \
                liboce-ocaf-lite-dev \
                liboce-ocaf-dev \
                oce-draw \
                libeigen3-dev \
                libqtwebkit-dev \
                libode-dev \
                libzipios++-dev \
                libfreetype6 \
                libfreetype6-dev \
                netgen-headers \
                libmedc-dev \
                libvtk6-dev \
                libproj-dev \
                gmsh " \
    && apt update \
    && apt install -y --no-install-recommends software-properties-common \
    && add-apt-repository -y ppa:deadsnakes/ppa \
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
                && rm FreeCAD/ freecad-build/ -fR \
                && ln -s /usr/local/bin/FreeCAD /usr/bin/freecad-git

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


# Clean
RUN apt-get clean \
    && rm /var/lib/apt/lists/* \
          /usr/share/doc/* \
          /usr/share/locale/* \
          /usr/share/man/* \
          /usr/share/info/* -fR    
