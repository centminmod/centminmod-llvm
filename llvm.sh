#!/bin/bash
######################################################
# llvm 4 compile for centos 7
######################################################
# variables
#############
DT=`date +"%d%m%y-%H%M%S"`

BUILD_DIR=/svr-setup
CENTMINLOGDIR=/root/centminlogs
######################################################
# functions
#############
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

buildllvm() {
  time yum -y install cmake3 svn
  cd "$BUILD_DIR"
  time svn co http://llvm.org/svn/llvm-project/llvm/branches/release_40/ llvm
  cd llvm/tools
  time svn co http://llvm.org/svn/llvm-project/cfe/branches/release_40/ clang
  cd clang/tools
  time svn co http://llvm.org/svn/llvm-project/clang-tools-extra/branches/release_40/ extra
  cd ../../../projects
  time svn co http://llvm.org/svn/llvm-project/compiler-rt/branches/release_40/ compiler-rt
  cd ../..
  mkdir llvm.build
  cd llvm.build
  time cmake3 -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/sbin/llvm ../llvm
  time make${MAKETHREADS}
  time make install
}
######################################################
starttime=$(TZ=UTC date +%s.%N)
  buildllvm
} 2>&1 | tee ${CENTMINLOGDIR}/centminmod_llvm_${DT}.log

endtime=$(TZ=UTC date +%s.%N)

INSTALLTIME=$(echo "scale=2;$endtime - $starttime"|bc )
echo "" >> ${CENTMINLOGDIR}/centminmod_llvm_${DT}.log
echo "Total LLVM 4 Build Time: $INSTALLTIME seconds" >> ${CENTMINLOGDIR}/centminmod_llvm_${DT}.log