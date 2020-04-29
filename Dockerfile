#
# Base image
#

# Set image
FROM mcr.microsoft.com/dotnet/core/runtime:3.1-buster-slim AS base

# Update
RUN apt update


#
# Dependencies
#

# Set image
FROM base AS dependencies

# Install all required packages
RUN apt install -y \
	build-essential \
	cmake \
	qt5-default \
	libgtk-3-dev \
	libavcodec-dev \
	libavformat-dev \
	libswscale-dev \
	libv4l-dev \#
# Base image
#

# Set image
FROM mcr.microsoft.com/dotnet/core/runtime:3.1-buster-slim AS base

# Update
RUN apt update


#
# Dependencies
#

# Set image
FROM base AS dependencies

# Install all required packages
RUN apt install -y \
	build-essential \
	cmake \
	qt5-default \
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
	qt5-default \
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
# Download
#

# Set image
FROM base AS download
WORKDIR /download

# Required packages
RUN apt install -y unzip wget

# Download required sources
RUN wget -O opencv.zip https://github.com/opencv/opencv/archive/4.3.0.zip
RUN wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/4.3.0.zip
RUN wget -O opencvsharp.zip https://github.com/shimat/opencvsharp/archive/4.3.0.20200405.zip

# Extract zips
RUN unzip opencv.zip
RUN unzip opencv_contrib.zip
RUN unzip opencvsharp.zip

# Rename folders
RUN mv opencv-4.3.0 opencv
RUN mv opencv_contrib-4.3.0 opencv_contrib
RUN mv opencvsharp-4.3.0.20200405 opencvsharp


#
# Build opencv
#

# Set image
FROM dependencies AS build-opencv

# Copy downloaded data
COPY --from=download /download/opencv /build/opencv
COPY --from=download /download/opencv_contrib /build/opencv_contrib

# Build
WORKDIR /build/opencv/build
RUN cmake \
	# Compiler params
	-D CMAKE_BUILD_TYPE=RELEASE \
	-D CMAKE_INSTALL_PREFIX=/build/dist \
	-D OPENCV_GENERATE_PKGCONFIG=YES \
	# Modules
	-D OPENCV_EXTRA_MODULES_PATH=/build/opencv_contrib/modules \
	# Set support
	-D WITH_FFMPEG=YES \
	-D WITH_GSTREAMER=YES \
	-D WITH_IPP=NO \
	-D WITH_1394=NO \
	-D WITH_LIBV4L=NO \
	-D WITH_V4l=NO \
	-D WITH_TBB=NO \
	-D WITH_GPHOTO2=NO \
	-D WITH_QT=NO \
	-D WITH_OPENGL=NO \
	# No examples
	-D INSTALL_PYTHON_EXAMPLES=NO \
	-D INSTALL_C_EXAMPLES=NO \
	-D BUILD_EXAMPLES=NO \
	-D BUILD_ANDROID_EXAMPLES=NO \
	# No tests
    -D BUILD_TESTS=NO \
	-D BUILD_PERF_TESTS=NO \
	# No docs
	-D BUILD_JAVA=NO \
	-D BUILD_DOCS=NO \
	# No unused platforms
	-D BUILD_opencv_java=NO \
	-D BUILD_opencv_python2=NO \
    -D BUILD_opencv_app=NO \
    -D BUILD_opencv_python=NO \
    -D BUILD_opencv_ts=NO \
    -D BUILD_opencv_js=NO \
	..
RUN make -j$(nproc)
RUN make install


#
# Build opencvsharp
#

# Set image
FROM dependencies AS build-opencvsharp

# Copy downloaded data
COPY --from=download /download/opencvsharp /build/opencvsharp

# Copy build data
COPY --from=build-opencv /build/dist /build/dist

# Build
WORKDIR /build/opencvsharp/src/build
RUN cmake -D CMAKE_INSTALL_PREFIX=/build/dist ..
RUN make -j$(nproc)
RUN make install


#
# Runtime
#

# Set image
FROM dependencies AS runtime
WORKDIR /app

# Copy from build (only opencvsharp is needed because it already contains opencv)
COPY --from=build-opencvsharp /build/dist /opencv/

# Libs
ENV LD_LIBRARY_PATH=/opencv/lib:/lib:/usr/lib:/usr/local/lib