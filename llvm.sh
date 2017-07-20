#!/bin/bash
######################################################
# llvm 4 or 5 compile for centos 7
######################################################
# variables
#############
DT=$(date +"%d%m%y-%H%M%S")
BINUTILS_VER='2.28'
# release_40 or release_50
CLANG_RELEASE='release_40'
LLVM_FOURGOLDGIT='n'

BUILD_DIR=/svr-setup
CENTMINLOGDIR=/root/centminlogs
######################################################
# functions
#############
CENTOSVER=$(awk '{ print $3 }' /etc/redhat-release)

if [ -f /proc/user_beancounters ]; then
    # CPUS='1'
    # MAKETHREADS=" -j$CPUS"
    # speed up make
    CPUS=$(grep -c "processor" /proc/cpuinfo)
    if [[ "$CPUS" -gt '8' ]]; then
        CPUS=$(echo "$CPUS+2" | bc)
    else
        CPUS=$(echo "$CPUS+1" | bc)
    fi
    MAKETHREADS=" -j$CPUS"
else
    # speed up make
    CPUS=$(grep -c "processor" /proc/cpuinfo)
    if [[ "$CPUS" -gt '8' ]]; then
        CPUS=$(echo "$CPUS+2" | bc)
    else
        CPUS=$(echo "$CPUS+1" | bc)
    fi
    MAKETHREADS=" -j$CPUS"
fi

if [ ! -d "$BUILD_DIR" ]; then
  mkdir -p $BUILD_DIR
fi

if [ ! -d "$CENTMINLOGDIR" ]; then
  mkdir -p $CENTMINLOGDIR
fi

if [ "$CENTOSVER" == 'release' ]; then
    CENTOSVER=$(cat /etc/redhat-release | awk '{ print $4 }' | cut -d . -f1,2)
    if [[ "$(cat /etc/redhat-release | awk '{ print $4 }' | cut -d . -f1)" = '7' ]]; then
        CENTOS_SEVEN='7'
    fi
fi

if [[ "$(cat /etc/redhat-release | awk '{ print $3 }' | cut -d . -f1)" = '6' ]]; then
    CENTOS_SIX='6'
fi

if [ "$CENTOSVER" == 'Enterprise' ]; then
    CENTOSVER=$(cat /etc/redhat-release | awk '{ print $7 }')
    OLS='y'
fi

if [[ "$CENTOS_SEVEN" != '7' ]]; then
  echo "CentOS 7 only"
  exit
fi

yuminstall_llvm() {
  if [[ ! "$(rpm -ql cmake3)" ]]; then
    time yum -y install cmake3
  fi
  if [[ ! "$(rpm -ql svn)" ]]; then
    time yum -y install svn
  fi
}

buildllvmgold() {
  # http://llvm.org/docs/GoldPlugin.html
  mkdir -p /home/buildtmp
  chmod -R 1777 /home/buildtmp
  export TMPDIR=/home/buildtmp
  export CC="/usr/bin/gcc"
  export CXX="/usr/bin/g++"

  cd "$BUILD_DIR"
  rm -rf llvmgold.binutils
  if [[ "$LLVM_FOURGOLDGIT" = [yY] ]]; then
    git clone --depth 1 git://sourceware.org/git/binutils-gdb.git binutils
  else
    if [[ ! -f "binutils-${BINUTILS_VER}.tar.gz" || ! -d "binutils-${BINUTILS_VER}" ]]; then
      wget -cnv "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VER}.tar.gz"
      tar xvzf "binutils-${BINUTILS_VER}.tar.gz"
    fi
  fi
  mkdir -p llvmgold.binutils
  cd llvmgold.binutils
  if [[ "$LLVM_FOURGOLDGIT" = [yY] ]]; then
    ../binutils/configure --enable-gold --enable-plugins --disable-werror
  else
    ../binutils-${BINUTILS_VER}/configure --enable-gold --enable-plugins --disable-werror
  fi
  if [[ "CPUS" -gt '8' ]]; then
    MAKETHREADS=' -j4'
  elif [[ "$CPUS" -le '8' && "CPUS" -gt '4' ]]; then
    MAKETHREADS=' -j2'
  elif [[ "$CPUS" -le '4' ]]; then
    MAKETHREADS=' -j1'
  fi
  time make${MAKETHREADS} all-gold
  time make${MAKETHREADS}
  time make install
  echo "/usr/local/bin/ld -v"
  /usr/local/bin/ld -v
  echo "/usr/local/bin/ld.gold -v"
  /usr/local/bin/ld.gold -v
  echo "/usr/local/bin/ld.bfd -v"
  /usr/local/bin/ld.bfd -v
}

buildllvm() {
  mkdir -p /home/buildtmp
  chmod -R 1777 /home/buildtmp
  export TMPDIR=/home/buildtmp
  export CC="/usr/bin/gcc"
  export CXX="/usr/bin/g++"

if [ -f /proc/user_beancounters ]; then
    # CPUS='1'
    # MAKETHREADS=" -j$CPUS"
    # speed up make
    CPUS=$(grep -c "processor" /proc/cpuinfo)
    if [[ "$CPUS" -gt '8' ]]; then
        CPUS=$(echo "$CPUS+2" | bc)
    else
        CPUS=$(echo "$CPUS+1" | bc)
    fi
    MAKETHREADS=" -j$CPUS"
else
    # speed up make
    CPUS=$(grep -c "processor" /proc/cpuinfo)
    if [[ "$CPUS" -gt '8' ]]; then
        CPUS=$(echo "$CPUS+2" | bc)
    else
        CPUS=$(echo "$CPUS+1" | bc)
    fi
    MAKETHREADS=" -j$CPUS"
fi

  cd "$BUILD_DIR"
  rm -rf llvm
  rm -rf "$BUILD_DIR/llvm.build/"
  time svn co http://llvm.org/svn/llvm-project/llvm/branches/${CLANG_RELEASE}/ llvm
  cd llvm/tools
  time svn co http://llvm.org/svn/llvm-project/cfe/branches/${CLANG_RELEASE}/ clang
  cd clang/tools
  time svn co http://llvm.org/svn/llvm-project/clang-tools-extra/branches/${CLANG_RELEASE}/ extra
  cd ../../../projects
  time svn co http://llvm.org/svn/llvm-project/compiler-rt/branches/${CLANG_RELEASE}/ compiler-rt
  cd ../..
  mkdir llvm.build
  cd llvm.build
  if [[ -f "$BUILD_DIR/binutils-${BINUTILS_VER}/include/plugin-api.h" ]]; then
    time cmake3 -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/sbin/llvm -DLLVM_BINUTILS_INCDIR="$BUILD_DIR/binutils-${BINUTILS_VER}/include" ../llvm
  else
    time cmake3 -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/sbin/llvm ../llvm
  fi
  time make${MAKETHREADS}
  time make install
  find . -name "LLVMgold.so"
}
######################################################
starttime=$(TZ=UTC date +%s.%N)
{
  yuminstall_llvm
  buildllvmgold
  buildllvm
} 2>&1 | tee ${CENTMINLOGDIR}/centminmod_llvm_${DT}.log

endtime=$(TZ=UTC date +%s.%N)

INSTALLTIME=$(echo "scale=2;$endtime - $starttime"|bc )
echo "" >> ${CENTMINLOGDIR}/centminmod_llvm_${DT}.log
if [[ "$CLANG_RELEASE" = 'release_40' ]]; then
  echo "Total LLVM 4 Build Time: $INSTALLTIME seconds" >> ${CENTMINLOGDIR}/centminmod_llvm_${DT}.log
elif [[ "$CLANG_RELEASE" = 'release_50' ]]; then
  echo "Total LLVM 5 Build Time: $INSTALLTIME seconds" >> ${CENTMINLOGDIR}/centminmod_llvm_${DT}.log
fi