#
# Base image
#

# Set image
FROM mcr.microsoft.com/dotnet/core/runtime:3.1-buster-slim AS base

# Update
RUN apt update


#
# Git
#

# Set image
FROM base AS git

# Install git
RUN apt install -y git

# Clone opencv
WORKDIR /opencv
RUN git clone https://github.com/opencv/opencv.git
WORKDIR /opencv/opencv
RUN git checkout 4.3.0

# Clone opencv-contrib
WORKDIR /opencv
RUN git clone https://github.com/opencv/opencv_contrib.git
WORKDIR /opencv/opencv_contrib
RUN git checkout 4.3.0

# Clone opencvsharp
WORKDIR /opencv
RUN git clone https://github.com/shimat/opencvsharp.git
WORKDIR /opencv/opencvsharp
RUN git checkout 4.3.0.20200405


#
# Dependencies
#

# Set image
FROM git AS dependencies

# Install
RUN apt install -y \
	build-essential \
	cmake \
	qt5-default

# Install needings
RUN apt install -y \
	libgtk-3-dev \
	libavcodec-dev \
	libavformat-dev \
	libswscale-dev \
	libv4l-dev \
	libxvidcore-dev \
	libx264-dev \
	libjpeg-dev \
	libpng-dev \
	libtiff-dev \
	libatlas-base-dev \
	libtbb2 \
	libtbb-dev \
	libdc1394-22-dev \
	libtiff5-dev \
	libxine2-dev \
	libgstreamer1.0-dev \
	libgstreamer-plugins-base1.0-dev \
	libgtk2.0-dev \
	libmp3lame-dev \
	libtheora-dev \
	libvorbis-dev \
	libopencore-amrnb-dev \
	libopencore-amrwb-dev \
	libprotobuf-dev \
	libgoogle-glog-dev \
	libgflags-dev \
	libgphoto2-dev \
	libeigen3-dev \
	libhdf5-dev \
	libavresample-dev \
	qt5-default

RUN apt install -y \
	x264 \
	pkg-config \
	gfortran \
	openexr \
	python3-dev \
	python3-numpy \
	yasm \
	v4l-utils \
	doxygen \
	software-properties-common \
	protobuf-compiler


#
# Build opencv
#

# Set image
FROM dependencies AS build-opencv

# Build
WORKDIR /opencv/opencv/build
RUN cmake \
	# Compiler params
	-D CMAKE_BUILD_TYPE=RELEASE \
	-D CMAKE_INSTALL_PREFIX=/opencv/dist \
	-D OPENCV_GENERATE_PKGCONFIG=YES \
	# Modules
	-D OPENCV_EXTRA_MODULES_PATH=/opencv/opencv_contrib/modules \
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
RUN make -j$(nproc)
RUN make install


#
# Build opencvsharp
#

# Set image
FROM dependencies AS build-opencvsharp

# Copy from opencv build
COPY --from=build-opencv /opencv/dist /opencv/dist

# Build
WORKDIR /opencv/opencvsharp/src/build
RUN cmake -D CMAKE_INSTALL_PREFIX=/opencv/dist ..
RUN make -j$(nproc)
RUN make install


#
# Runtime
#

# Set image
FROM dependencies AS runtime
WORKDIR /app

# Copy from builds
COPY --from=build-opencv /opencv/dist /opencv/dist
COPY --from=build-opencvsharp /opencv/dist /opencv/dist

# Libs
ENV LD_LIBRARY_PATH=/opencv/dist/lib:/lib:/usr/lib:/usr/local/lib
