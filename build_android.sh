# returns value of specific key in given section
# $1 - file
# $2 - key
# $3 - section
function readini() {
  echo "$(sed -nr "/^\[$2\]/ { :l /^$3[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" $1)"
}

BUILDPATH=$(cd $(dirname $0) && pwd)
shellFileName=`basename "$0"`
configFile="${shellFileName%%.*}.ini"
configFile=$BUILDPATH/$configFile
LLVM_DIR=$BUILDPATH/llvm-project
CMAKE=cmake
MAKE=ninja
GENERATOR=Ninja
BUILD_DIR=build
RELEASE_DIR=release
ANDROID_NDK=
ANDROID_API_LEVEL=21
TARGET_ABI_LIST="armeabi-v7a arm64-v8a x86 x86_64"
BUILD_TYPE_LIST="Release Debug"
CMAKE=$(readini $configFile build CMAKE_PROGRAM)
MAKE=$(readini $configFile build CMAKE_MAKE_PROGRAM)
GENERATOR=$(readini $configFile build GENERATOR)
BUILD_DIR=$(readini $configFile build BUILD_DIR)
BUILD_DIR=$BUILDPATH/$BUILD_DIR
RELEASE_DIR=$(readini $configFile build RELEASE_DIR)
RELEASE_DIR=$BUILDPATH/$RELEASE_DIR
ANDROID_NDK=$(readini $configFile build ANDROID_NDK)
ANDROID_API_LEVEL=$(readini $configFile build ANDROID_API_LEVEL)
TARGET_ABI_LIST=$(readini $configFile build ANDROID_ABI_LIST)
BUILD_TYPE_LIST=$(readini $configFile build BUILD_TYPE_LIST)
declare -a TARGET_ABI_LIST=($TARGET_ABI_LIST)
declare -a BUILD_TYPE_LIST=($BUILD_TYPE_LIST)

for BUILD_TYPE in "${BUILD_TYPE_LIST[@]}"
do
	for TARGET_ABI in "${TARGET_ABI_LIST[@]}"
	do
		PROJECT_BUILD_DIR=$BUILD_DIR/android_$TARGET_ABI/$BUILD_TYPE

		echo
		echo
		command_generator="$CMAKE -Wno-dev -G $GENERATOR -S $BUILDPATH -B $PROJECT_BUILD_DIR -DCMAKE_INSTALL_PREFIX=$PROJECT_BUILD_DIR \
-DCMAKE_MAKE_PROGRAM=$MAKE \
-DCMAKE_BINARY_DIR=$BUILD_DIR \
-DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
-DCMAKE_BUILD_TYPE=$BUILD_TYPE \
-DCMAKE_SYSTEM_NAME=Android \
-DANDROID_NDK=$ANDROID_NDK \
-DANDROID_ABI=$TARGET_ABI \
-DANDROID_PLATFORM=$ANDROID_API_LEVEL \
-DTARGET_ABI=$TARGET_ABI \
-DRELEASE_DIR=$RELEASE_DIR \
-DLLVM_DIR=$LLVM_DIR"
		echo $command_generator
		$command_generator

		echo
		echo
		command_build="$CMAKE --build $PROJECT_BUILD_DIR --config=$BUILD_TYPE --target=install-cxxandcxxabi"
		echo $command_build
		$command_build

		echo
		echo
		command_build="$CMAKE --build $PROJECT_BUILD_DIR --config=$BUILD_TYPE --target=install-cxxandcxxabi-stripped"
		echo $command_build
		$command_build
	done
done
