FROM ubuntu:18.04 AS build-env

#
# Install
#

# General
RUN apt update
RUN apt upgrade -y
RUN apt dist-upgrade -y
RUN apt install -y pgp
RUN apt install -y wget
RUN apt install -y git
RUN apt install -y apt-utils
RUN apt install -y software-properties-common
RUN apt install -y apt-transport-https

# Prepare dotnet installation
RUN wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN add-apt-repository universe
RUN apt update
RUN apt install -y dotnet-sdk-2.2 -y


#
# OpenCV
# https://cv-tricks.com/installation/opencv-4-1-ubuntu18-04/
# + for repo on first line: https://www.pyimagesearch.com/2018/05/28/ubuntu-18-04-how-to-install-opencv/
#

# Required dependencies
RUN add-apt-repository "deb http://security.ubuntu.com/ubuntu xenial-security main"
RUN apt update -y # Update the list of packages
RUN apt remove -y x264 libx264-dev # Remove the older version of libx264-dev and x264
RUN apt install -y build-essential checkinstall cmake pkg-config yasm
RUN apt install -y libjpeg8-dev libjasper-dev libpng12-dev
RUN apt install -y libtiff5-dev
RUN apt install -y libavcodec-dev libavformat-dev libswscale-dev libdc1394-22-dev
RUN apt install -y libxine2-dev libv4l-dev
RUN apt install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
RUN apt install -y qt5-default libgtk2.0-dev libtbb-dev
RUN apt install -y libatlas-base-dev
RUN apt install -y libfaac-dev libmp3lame-dev libtheora-dev
RUN apt install -y libvorbis-dev libxvidcore-dev
RUN apt install -y libopencore-amrnb-dev libopencore-amrwb-dev
RUN apt install -y x264 v4l-utils

# Optional dependencies
RUN apt install -y libprotobuf-dev protobuf-compiler
RUN apt install -y libgoogle-glog-dev libgflags-dev
RUN apt install -y libgphoto2-dev libeigen3-dev libhdf5-dev doxygen

# Download OpenCV from Github
WORKDIR /opencv
RUN git clone https://github.com/opencv/opencv.git
WORKDIR /opencv/opencv
RUN git checkout 4.1.0
 
# Download OpenCV_contrib from Github
WORKDIR /opencv
RUN git clone https://github.com/opencv/opencv_contrib.git
WORKDIR /opencv/opencv_contrib
RUN git checkout 4.1.0

# Build
WORKDIR /opencv/opencv/build
RUN cmake \
        # Compiler params
        -D CMAKE_BUILD_TYPE=RELEASE \
        -D CMAKE_INSTALL_PREFIX=/usr/local \
		-D OPENCV_GENERATE_PKGCONFIG=YES \
        # Modules
		-D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
		# No examples
        -D INSTALL_PYTHON_EXAMPLES=NO \
        -D INSTALL_C_EXAMPLES=NO \
        # Support
        -D WITH_IPP=NO \
        -D WITH_1394=NO \
        -D WITH_LIBV4L=NO \
        -D WITH_V4l=YES \
        -D WITH_TBB=YES \
        -D WITH_FFMPEG=YES \
        -D WITH_GPHOTO2=YES \
        -D WITH_GSTREAMER=YES \
        -D WITH_QT=YES \
		-D WITH_OPENGL=YES \
		# NO doc test and other bindings
        -D BUILD_DOCS=NO \
        -D BUILD_TESTS=NO \
        -D BUILD_PERF_TESTS=NO \
        -D BUILD_EXAMPLES=NO \
        -D BUILD_opencv_java=NO \
        -D BUILD_opencv_python2=NO \
        -D BUILD_ANDROID_EXAMPLES=NO ..
RUN NPROC=$(nproc); make -j$NPROC
RUN make install

# Setup libraries
ENV LD_LIBRARY_PATH=/lib:/usr/lib:/usr/local/lib


#
# Here your code...
#