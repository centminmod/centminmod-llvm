#!/bin/bash
######################################################
# llvm 4 & 5 & 6 compile for centos 7
# for centminmod.com lemp stacks
######################################################
# variables
#############
DT=$(date +"%d%m%y-%H%M%S")
BINUTILS_VER='2.30'
BINUTILS_ALWAYS='n'
# release_40 or release_50 or release_60
CLANG_RELEASE='release_60'
# build both clang 4 and 5
CLANG_ALL='n'
# LLVM
LLVM_USEGITHUB='n'
LLVM_FOURGOLDGIT='n'
LLVM_LTO='n'
LLVM_CCACHE='y'
LLVM_WITHCLANG='n'
LLVM_BOLT='n'
NINAJABUILD='n'

BUILD_DIR=/svr-setup
CENTMINLOGDIR=/root/centminlogs
######################################################
# functions
#############
CENTOSVER=$(awk '{ print $3 }' /etc/redhat-release)

if [[ "$CLANG_ALL" = [yY] ]]; then
  CLANG_RELEASE='release_40 release_50 release_60'
else
  CLANG_RELEASE=$CLANG_RELEASE
fi

if [[ "$LLVM_BOLT" = [yY] ]]; then
  LLVM_USEGITHUB='y'
  CLANG_RELEASE='release_master'
fi

if [[ "$LLVM_USEGITHUB" = [yY] ]]; then
  CLANG_RELEASE='release_master'
fi

if [[ "$LLVM_LTO" = [yY] ]]; then
  LTO_VALUE=On
else
  LTO_VALUE=Off
fi

if [[ "$LLVM_CCACHE" = [yY] ]]; then
  LLVM_CCACHEOPT=' -DLLVM_CCACHE_BUILD=On'
else
  LLVM_CCACHEOPT=''
fi

if [ -f /proc/user_beancounters ]; then
    # CPUS='1'
    # MAKETHREADS=" -j$CPUS"
    # speed up make
    CPUS=$(grep -c "processor" /proc/cpuinfo)
    if [[ "$CPUS" -gt '8' ]]; then
        CPUS=$(echo "$CPUS+1" | bc)
    else
        CPUS=$(echo "$CPUS" | bc)
    fi
    MAKETHREADS=" -j$CPUS"
else
    # speed up make
    CPUS=$(grep -c "processor" /proc/cpuinfo)
    if [[ "$CPUS" -gt '8' ]]; then
        CPUS=$(echo "$CPUS+1" | bc)
    else
        CPUS=$(echo "$CPUS" | bc)
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

tidyup() {
    # logs older than 5 days will be gzip compressed to save space 
    if [ -d /root/centminlogs ]; then
        # find /root/centminlogs -type f -mtime +3 \( -name 'tools-binutils-install_*.log"' -o -name 'tools-gcc-install*.log' \) -exec ls -lah {} \;
        find /root/centminlogs -type f -mtime +3 \( -name 'centminmod_llvm_*.log"' -o -name 'centminmod_llvm*.log' \) -exec gzip -9 {} \;
    fi
}


yuminstall_llvm() {
  if [[ ! -f /usr/bin/cmake3 ]]; then
    time yum -y install cmake3
  fi
  if [[ ! -f /usr/bin/svn ]]; then
    time yum -y install svn
  fi
  if [[ ! -f /usr/bin/ninja-build ]]; then
    yum -y install ninja-build
  fi
  if [[ -f /usr/local/src/centminmod/addons/devtoolset-7.sh && -f /opt/rh/devtoolset-7/root/bin/gcc ]]; then
    DEVTOOLSET='y'
    source /opt/rh/devtoolset-7/enable
    gcc --version
    # alternatives --altdir /opt/rh/devtoolset-7/root/etc/alternatives --admindir /opt/rh/devtoolset-7/root/var/lib/alternatives --config ld
    alternatives --altdir /opt/rh/devtoolset-7/root/etc/alternatives --admindir /opt/rh/devtoolset-7/root/var/lib/alternatives --set ld /opt/rh/devtoolset-7/root/usr/bin/ld.gold
    alternatives --altdir /opt/rh/devtoolset-7/root/etc/alternatives --admindir /opt/rh/devtoolset-7/root/var/lib/alternatives --list
    export CC="/opt/rh/devtoolset-7/root/bin/gcc -flto -fuse-ld=gold -gsplit-dwarf -Wimplicit-fallthrough=0"
    export CXX="/opt/rh/devtoolset-7/root/bin/g++"
  elif [[ -f /usr/local/src/centminmod/addons/devtoolset-7.sh && ! -f /opt/rh/devtoolset-7/root/bin/gcc ]]; then
    /usr/local/src/centminmod/addons/devtoolset-7.sh
    source /opt/rh/devtoolset-7/enable
    gcc --version
    # alternatives --altdir /opt/rh/devtoolset-7/root/etc/alternatives --admindir /opt/rh/devtoolset-7/root/var/lib/alternatives --config ld
    alternatives --altdir /opt/rh/devtoolset-7/root/etc/alternatives --admindir /opt/rh/devtoolset-7/root/var/lib/alternatives --set ld /opt/rh/devtoolset-7/root/usr/bin/ld.gold
    alternatives --altdir /opt/rh/devtoolset-7/root/etc/alternatives --admindir /opt/rh/devtoolset-7/root/var/lib/alternatives --list
    export CC="/opt/rh/devtoolset-7/root/bin/gcc -flto -fuse-ld=gold -gsplit-dwarf -Wimplicit-fallthrough=0"
    export CXX="/opt/rh/devtoolset-7/root/bin/g++"
    DEVTOOLSET='y'
  fi
  if [[ -f /usr/local/src/centminmod/addons/devtoolset-6.sh && -f /opt/rh/devtoolset-6/root/bin/gcc ]]; then
    DEVTOOLSET='y'
    source /opt/rh/devtoolset-6/enable
    gcc --version
    # alternatives --altdir /opt/rh/devtoolset-6/root/etc/alternatives --admindir /opt/rh/devtoolset-6/root/var/lib/alternatives --config ld
    alternatives --altdir /opt/rh/devtoolset-6/root/etc/alternatives --admindir /opt/rh/devtoolset-6/root/var/lib/alternatives --set ld /opt/rh/devtoolset-6/root/usr/bin/ld.gold
    alternatives --altdir /opt/rh/devtoolset-6/root/etc/alternatives --admindir /opt/rh/devtoolset-6/root/var/lib/alternatives --list
    export CC="/opt/rh/devtoolset-6/root/bin/gcc -flto -fuse-ld=gold -gsplit-dwarf"
    export CXX="/opt/rh/devtoolset-6/root/bin/g++"
  elif [[ -f /usr/local/src/centminmod/addons/devtoolset-6.sh && ! -f /opt/rh/devtoolset-6/root/bin/gcc ]]; then
    /usr/local/src/centminmod/addons/devtoolset-6.sh
    source /opt/rh/devtoolset-6/enable
    gcc --version
    # alternatives --altdir /opt/rh/devtoolset-6/root/etc/alternatives --admindir /opt/rh/devtoolset-6/root/var/lib/alternatives --config ld
    alternatives --altdir /opt/rh/devtoolset-6/root/etc/alternatives --admindir /opt/rh/devtoolset-6/root/var/lib/alternatives --set ld /opt/rh/devtoolset-6/root/usr/bin/ld.gold
    alternatives --altdir /opt/rh/devtoolset-6/root/etc/alternatives --admindir /opt/rh/devtoolset-6/root/var/lib/alternatives --list
    export CC="/opt/rh/devtoolset-6/root/bin/gcc -flto -fuse-ld=gold -gsplit-dwarf"
    export CXX="/opt/rh/devtoolset-6/root/bin/g++"
    DEVTOOLSET='y'
  fi
}

buildllvmgold() {
  # skip llvmgold compile if binutils version matches the source compiled version already or if doesn't exist
  if [[ "$BINUTILS_ALWAYS" = [yY] ]] || [[ ! -f /usr/local/bin/ld ]] || [[ -f /usr/local/bin/ld && "$(/usr/local/bin/ld -v | awk '{print $5}')" != "$BINUTILS_VER" ]]; then
    # http://llvm.org/docs/GoldPlugin.html
    mkdir -p /home/buildtmp
    chmod -R 1777 /home/buildtmp
    export TMPDIR=/home/buildtmp
    if [[ -f /usr/local/src/centminmod/addons/devtoolset-7.sh && ! -f /opt/rh/devtoolset-7/root/bin/gcc ]]; then
      /usr/local/src/centminmod/addons/devtoolset-7.sh
      source /opt/rh/devtoolset-7/enable
      gcc --version
      # alternatives --altdir /opt/rh/devtoolset-7/root/etc/alternatives --admindir /opt/rh/devtoolset-7/root/var/lib/alternatives --config ld
      alternatives --altdir /opt/rh/devtoolset-7/root/etc/alternatives --admindir /opt/rh/devtoolset-7/root/var/lib/alternatives --set ld /opt/rh/devtoolset-7/root/usr/bin/ld.gold
      alternatives --altdir /opt/rh/devtoolset-7/root/etc/alternatives --admindir /opt/rh/devtoolset-7/root/var/lib/alternatives --list
      if [[ "$LLVM_CCACHE" = [yY] ]]; then
        if [[ -f /usr/local/src/centminmod/addons/devtoolset-7.sh && -f /opt/rh/devtoolset-7/root/bin/gcc ]]; then
          export CC="ccache /opt/rh/devtoolset-7/root/bin/gcc -fuse-ld=gold -gsplit-dwarf -Wimplicit-fallthrough=0"
          export CXX="ccache /opt/rh/devtoolset-7/root/bin/g++"
        fi
      else
        if [[ -f /usr/local/src/centminmod/addons/devtoolset-7.sh && -f /opt/rh/devtoolset-7/root/bin/gcc ]]; then
          export CC="/opt/rh/devtoolset-7/root/bin/gcc -fuse-ld=gold -gsplit-dwarf -Wimplicit-fallthrough=0"
          export CXX="/opt/rh/devtoolset-7/root/bin/g++"
        fi
      fi
    elif [[ -f /usr/local/src/centminmod/addons/devtoolset-7.sh && -f /opt/rh/devtoolset-7/root/bin/gcc ]]; then
      source /opt/rh/devtoolset-7/enable
      gcc --version
      # alternatives --altdir /opt/rh/devtoolset-7/root/etc/alternatives --admindir /opt/rh/devtoolset-7/root/var/lib/alternatives --config ld
      alternatives --altdir /opt/rh/devtoolset-7/root/etc/alternatives --admindir /opt/rh/devtoolset-7/root/var/lib/alternatives --set ld /opt/rh/devtoolset-7/root/usr/bin/ld.gold
      alternatives --altdir /opt/rh/devtoolset-7/root/etc/alternatives --admindir /opt/rh/devtoolset-7/root/var/lib/alternatives --list
      if [[ "$LLVM_CCACHE" = [yY] ]]; then
        if [[ -f /usr/local/src/centminmod/addons/devtoolset-7.sh && -f /opt/rh/devtoolset-7/root/bin/gcc ]]; then
          export CC="ccache /opt/rh/devtoolset-7/root/bin/gcc -fuse-ld=gold -gsplit-dwarf -Wimplicit-fallthrough=0"
          export CXX="ccache /opt/rh/devtoolset-7/root/bin/g++"
        fi
      else
        if [[ -f /usr/local/src/centminmod/addons/devtoolset-7.sh && -f /opt/rh/devtoolset-7/root/bin/gcc ]]; then
          export CC="/opt/rh/devtoolset-7/root/bin/gcc -fuse-ld=gold -gsplit-dwarf -Wimplicit-fallthrough=0"
          export CXX="/opt/rh/devtoolset-7/root/bin/g++"
        fi
      fi
    elif [[ -f /usr/local/src/centminmod/addons/devtoolset-6.sh && ! -f /opt/rh/devtoolset-6/root/bin/gcc ]]; then
      /usr/local/src/centminmod/addons/devtoolset-6.sh
      source /opt/rh/devtoolset-6/enable
      gcc --version
      # alternatives --altdir /opt/rh/devtoolset-6/root/etc/alternatives --admindir /opt/rh/devtoolset-6/root/var/lib/alternatives --config ld
      alternatives --altdir /opt/rh/devtoolset-6/root/etc/alternatives --admindir /opt/rh/devtoolset-6/root/var/lib/alternatives --set ld /opt/rh/devtoolset-6/root/usr/bin/ld.gold
      alternatives --altdir /opt/rh/devtoolset-6/root/etc/alternatives --admindir /opt/rh/devtoolset-6/root/var/lib/alternatives --list
      if [[ "$LLVM_CCACHE" = [yY] ]]; then
        if [[ -f /usr/local/src/centminmod/addons/devtoolset-6.sh && -f /opt/rh/devtoolset-6/root/bin/gcc ]]; then
          export CC="ccache /opt/rh/devtoolset-6/root/bin/gcc -fuse-ld=gold -gsplit-dwarf"
          export CXX="ccache /opt/rh/devtoolset-6/root/bin/g++"
        fi
      else
        if [[ -f /usr/local/src/centminmod/addons/devtoolset-6.sh && -f /opt/rh/devtoolset-6/root/bin/gcc ]]; then
          export CC="/opt/rh/devtoolset-6/root/bin/gcc -fuse-ld=gold -gsplit-dwarf"
          export CXX="/opt/rh/devtoolset-6/root/bin/g++"
        fi
      fi
    elif [[ -f /usr/local/src/centminmod/addons/devtoolset-6.sh && -f /opt/rh/devtoolset-6/root/bin/gcc ]]; then
      source /opt/rh/devtoolset-6/enable
      gcc --version
      # alternatives --altdir /opt/rh/devtoolset-6/root/etc/alternatives --admindir /opt/rh/devtoolset-6/root/var/lib/alternatives --config ld
      alternatives --altdir /opt/rh/devtoolset-6/root/etc/alternatives --admindir /opt/rh/devtoolset-6/root/var/lib/alternatives --set ld /opt/rh/devtoolset-6/root/usr/bin/ld.gold
      alternatives --altdir /opt/rh/devtoolset-6/root/etc/alternatives --admindir /opt/rh/devtoolset-6/root/var/lib/alternatives --list
      if [[ "$LLVM_CCACHE" = [yY] ]]; then
        if [[ -f /usr/local/src/centminmod/addons/devtoolset-6.sh && -f /opt/rh/devtoolset-6/root/bin/gcc ]]; then
          export CC="ccache /opt/rh/devtoolset-6/root/bin/gcc -fuse-ld=gold -gsplit-dwarf"
          export CXX="ccache /opt/rh/devtoolset-6/root/bin/g++"
        fi
      else
        if [[ -f /usr/local/src/centminmod/addons/devtoolset-6.sh && -f /opt/rh/devtoolset-6/root/bin/gcc ]]; then
          export CC="/opt/rh/devtoolset-6/root/bin/gcc -fuse-ld=gold -gsplit-dwarf"
          export CXX="/opt/rh/devtoolset-6/root/bin/g++"
        fi
      fi
    else
      if [[ "$LLVM_CCACHE" = [yY] ]]; then
        export CC="ccache /usr/bin/gcc -fuse-ld=gold -gsplit-dwarf"
        export CXX="ccache /usr/bin/g++"
      else
        export CC="/usr/bin/gcc -fuse-ld=gold -gsplit-dwarf"
        export CXX="/usr/bin/g++"
      fi
    fi
  
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
      ../binutils/configure --enable-gold --enable-plugins --disable-nls --disable-werror
    else
      ../binutils-${BINUTILS_VER}/configure --enable-gold --enable-plugins --disable-nls --disable-werror
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
  fi
}

buildllvm() {
  mkdir -p /home/buildtmp
  chmod -R 1777 /home/buildtmp
  export TMPDIR=/home/buildtmp
  # export CC="/usr/bin/gcc"
  # export CXX="/usr/bin/g++"

if [ -f /proc/user_beancounters ]; then
    # CPUS='1'
    # MAKETHREADS=" -j$CPUS"
    # speed up make
    CPUS=$(grep -c "processor" /proc/cpuinfo)
    if [[ "$CPUS" -gt '8' ]]; then
        CPUS=$(echo "$CPUS+1" | bc)
    else
        CPUS=$(echo "$CPUS" | bc)
    fi
    MAKETHREADS=" -j$CPUS"
else
    # speed up make
    CPUS=$(grep -c "processor" /proc/cpuinfo)
    if [[ "$CPUS" -gt '8' ]]; then
        CPUS=$(echo "$CPUS+1" | bc)
    else
        CPUS=$(echo "$CPUS" | bc)
    fi
    MAKETHREADS=" -j$CPUS"
fi

  for v in $CLANG_RELEASE; do
    cd "$BUILD_DIR"
    rm -rf llvm
    rm -rf "$BUILD_DIR/llvm.build/"
    if [[ "$LLVM_USEGITHUB" = [yY] ]]; then
      time git clone --depth=1 https://github.com/llvm-mirror/llvm llvm
      if [[ "$LLVM_BOLT" != [yY] ]]; then
        pushd llvm
        git checkout -b ${v}
        popd
      fi
    else
      time svn co http://llvm.org/svn/llvm-project/llvm/branches/${v}/ llvm
    fi
    cd llvm/tools
    if [[ "$LLVM_USEGITHUB" = [yY] ]]; then
      time git clone --depth=1 https://github.com/llvm-mirror/clang clang
      if [[ "$LLVM_BOLT" != [yY] ]]; then
        pushd clang
        git checkout -b ${v}
        popd
      fi
    else
      time svn co http://llvm.org/svn/llvm-project/cfe/branches/${v}/ clang
    fi
    if [[ "$LLVM_BOLT" = [yY] ]]; then
      echo
      echo "git checkout -b llvm-bolt f137ed238db11440f03083b1c88b7ffc0f4af65e"
      git checkout -b llvm-bolt f137ed238db11440f03083b1c88b7ffc0f4af65e
      echo
      echo "git clone https://github.com/facebookincubator/BOLT llvm-bolt"
      git clone https://github.com/facebookincubator/BOLT llvm-bolt
      echo
    fi
    cd clang/tools
    if [[ "$LLVM_USEGITHUB" = [yY] ]]; then
      time git clone --depth=1 https://github.com/llvm-mirror/clang-tools-extra extra
      if [[ "$LLVM_BOLT" != [yY] ]]; then
        pushd extra
        git checkout -b ${v}
        popd
      fi
    else
      time svn co http://llvm.org/svn/llvm-project/clang-tools-extra/branches/${v}/ extra
    fi
    cd ../../../projects
    if [[ "$LLVM_USEGITHUB" = [yY] ]]; then
      time git clone --depth=1 https://github.com/llvm-mirror/compiler-rt compiler-rt
      if [[ "$LLVM_BOLT" != [yY] ]]; then
        pushd compiler-rt
        git checkout -b ${v}
        popd
      fi
    else
      time svn co http://llvm.org/svn/llvm-project/compiler-rt/branches/${v}/ compiler-rt
    fi
    cd ../..
    if [[ "$LLVM_BOLT" = [yY] ]]; then
      pushd llvm
      echo
      echo "patch -p 1 < tools/llvm-bolt/llvm.patch"
      patch -p 1 < tools/llvm-bolt/llvm.patch
      echo
      popd
    fi
    mkdir llvm.build
    cd llvm.build
    if [[ -f "$BUILD_DIR/binutils-${BINUTILS_VER}/include/plugin-api.h" ]]; then
      if [[ "$DEVTOOLSET" = [yY] ]]; then
        if [[ "$NINAJABUILD" = [yY] ]]; then
          if [[ "$v" = 'release_50' && -f /opt/sbin/llvm-release_40/bin/clang && "$LLVM_WITHCLANG" = [yY] ]]; then
            if [[ "$LLVM_CCACHE" = [yY] ]]; then
              export CC="ccache /opt/sbin/llvm-release_40/bin/clang -fuse-ld=gold -gsplit-dwarf"
              export CXX="ccache /opt/sbin/llvm-release_40/bin/clang++"
            else
              export CC="/opt/sbin/llvm-release_40/bin/clang -fuse-ld=gold -gsplit-dwarf"
              export CXX="/opt/sbin/llvm-release_40/bin/clang++"
            fi
            time cmake3 -G "Ninja" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_C_COMPILER=/opt/sbin/llvm-release_40/bin/clang -DCMAKE_CXX_COMPILER=/opt/sbin/llvm-release_40/bin/clang++ -DCMAKE_CXX_LINK_FLAGS="-Wl,-rpath,/opt/sbin/llvm-release_40/lib -L/opt/sbin/llvm-release_40/lib" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/sbin/llvm-${v} -DCMAKE_RANLIB=/opt/sbin/llvm-release_40/bin/llvm-ranlib -DCMAKE_AR=/opt/sbin/llvm-release_40/bin/llvm-ar -DLLVM_TARGETS_TO_BUILD="X86" -DLLVM_ENABLE_LTO=${LTO_VALUE} -DLLVM_USE_LINKER=gold${LLVM_CCACHEOPT} -DLLVM_BINUTILS_INCDIR="$BUILD_DIR/binutils-${BINUTILS_VER}/include" ../llvm
          else
            time cmake3 -G "Ninja" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_C_COMPILER=/opt/rh/devtoolset-6/root/bin/gcc -DCMAKE_CXX_COMPILER=/opt/rh/devtoolset-6/root/bin/g++ -DCMAKE_CXX_LINK_FLAGS="-Wl,-rpath,/opt/rh/devtoolset-6/root/usr/lib64 -L/opt/rh/devtoolset-6/root/usr/lib64" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/sbin/llvm-${v} -DCMAKE_RANLIB=/opt/rh/devtoolset-6/root/usr/libexec/gcc/x86_64-redhat-linux/6.3.1/ranlib -DCMAKE_AR=/opt/rh/devtoolset-6/root/usr/libexec/gcc/x86_64-redhat-linux/6.3.1/ar -DLLVM_TARGETS_TO_BUILD="X86" -DLLVM_ENABLE_LTO=${LTO_VALUE} -DLLVM_USE_LINKER=gold${LLVM_CCACHEOPT} -DLLVM_BINUTILS_INCDIR="$BUILD_DIR/binutils-${BINUTILS_VER}/include" ../llvm
          fi
        else
          if [[ "$v" = 'release_50' && -f /opt/sbin/llvm-release_40/bin/clang && "$LLVM_WITHCLANG" = [yY] ]]; then
            if [[ "$LLVM_CCACHE" = [yY] ]]; then
              export CC="ccache /opt/sbin/llvm-release_40/bin/clang -fuse-ld=gold -gsplit-dwarf"
              export CXX="ccache /opt/sbin/llvm-release_40/bin/clang++"
            else
              export CC="/opt/sbin/llvm-release_40/bin/clang -fuse-ld=gold -gsplit-dwarf"
              export CXX="/opt/sbin/llvm-release_40/bin/clang++"
            fi
            time cmake3 -G "Unix Makefiles" -DCMAKE_C_COMPILER=/opt/sbin/llvm-release_40/bin/clang -DCMAKE_CXX_COMPILER=/opt/sbin/llvm-release_40/bin/clang++ -DCMAKE_CXX_LINK_FLAGS="-Wl,-rpath,/opt/sbin/llvm-release_40/lib -L/opt/sbin/llvm-release_40/lib" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/sbin/llvm-${v} -DCMAKE_RANLIB=/opt/sbin/llvm-release_40/bin/llvm-ranlib -DCMAKE_AR=/opt/sbin/llvm-release_40/bin/llvm-ar -DLLVM_TARGETS_TO_BUILD="X86" -DLLVM_ENABLE_LTO=${LTO_VALUE} -DLLVM_USE_LINKER=gold${LLVM_CCACHEOPT} -DLLVM_BINUTILS_INCDIR="$BUILD_DIR/binutils-${BINUTILS_VER}/include" ../llvm
          else
            time cmake3 -G "Unix Makefiles" -DCMAKE_C_COMPILER=/opt/rh/devtoolset-6/root/bin/gcc -DCMAKE_CXX_COMPILER=/opt/rh/devtoolset-6/root/bin/g++ -DCMAKE_CXX_LINK_FLAGS="-Wl,-rpath,/opt/rh/devtoolset-6/root/usr/lib64 -L/opt/rh/devtoolset-6/root/usr/lib64" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/sbin/llvm-${v} -DCMAKE_RANLIB=/opt/rh/devtoolset-6/root/usr/libexec/gcc/x86_64-redhat-linux/6.3.1/ranlib -DCMAKE_AR=/opt/rh/devtoolset-6/root/usr/libexec/gcc/x86_64-redhat-linux/6.3.1/ar -DLLVM_TARGETS_TO_BUILD="X86" -DLLVM_ENABLE_LTO=${LTO_VALUE} -DLLVM_USE_LINKER=gold${LLVM_CCACHEOPT} -DLLVM_BINUTILS_INCDIR="$BUILD_DIR/binutils-${BINUTILS_VER}/include" ../llvm
          fi
        fi
      else
        if [[ "$NINAJABUILD" = [yY] ]]; then
          time cmake3 -G "Ninja" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/sbin/llvm-${v} -DLLVM_TARGETS_TO_BUILD="X86" -DLLVM_BINUTILS_INCDIR="$BUILD_DIR/binutils-${BINUTILS_VER}/include" ../llvm
        else
          time cmake3 -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/sbin/llvm-${v} -DLLVM_TARGETS_TO_BUILD="X86" -DLLVM_BINUTILS_INCDIR="$BUILD_DIR/binutils-${BINUTILS_VER}/include" ../llvm
        fi
      fi
    else
      if [[ "$DEVTOOLSET" = [yY] ]]; then
        if [[ "$NINAJABUILD" = [yY] ]]; then
          time cmake3 -G "Ninja" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_C_COMPILER=/opt/rh/devtoolset-6/root/bin/gcc -DCMAKE_CXX_COMPILER=/opt/rh/devtoolset-6/root/bin/g++ -DCMAKE_CXX_LINK_FLAGS="-Wl,-rpath,/opt/rh/devtoolset-6/root/usr/lib64 -L/opt/rh/devtoolset-6/root/usr/lib64" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/sbin/llvm-${v} -DCMAKE_RANLIB=/opt/rh/devtoolset-6/root/usr/libexec/gcc/x86_64-redhat-linux/6.3.1/ranlib -DCMAKE_AR=/opt/rh/devtoolset-6/root/usr/libexec/gcc/x86_64-redhat-linux/6.3.1/ar -DLLVM_TARGETS_TO_BUILD="X86" -DLLVM_ENABLE_LTO=${LTO_VALUE} -DLLVM_USE_LINKER=gold${LLVM_CCACHEOPT} ../llvm
        else
          time cmake3 -G "Unix Makefiles" -DCMAKE_C_COMPILER=/opt/rh/devtoolset-6/root/bin/gcc -DCMAKE_CXX_COMPILER=/opt/rh/devtoolset-6/root/bin/g++ -DCMAKE_CXX_LINK_FLAGS="-Wl,-rpath,/opt/rh/devtoolset-6/root/usr/lib64 -L/opt/rh/devtoolset-6/root/usr/lib64" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/sbin/llvm-${v} -DCMAKE_RANLIB=/opt/rh/devtoolset-6/root/usr/libexec/gcc/x86_64-redhat-linux/6.3.1/ranlib -DCMAKE_AR=/opt/rh/devtoolset-6/root/usr/libexec/gcc/x86_64-redhat-linux/6.3.1/ar -DLLVM_TARGETS_TO_BUILD="X86" -DLLVM_ENABLE_LTO=${LTO_VALUE} -DLLVM_USE_LINKER=gold${LLVM_CCACHEOPT} ../llvm
        fi
      else
        if [[ "$NINAJABUILD" = [yY] ]]; then
          time cmake3 -G "Ninja" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/sbin/llvm-${v} -DLLVM_TARGETS_TO_BUILD="X86" ../llvm
        else
          time cmake3 -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/sbin/llvm-${v} -DLLVM_TARGETS_TO_BUILD="X86" ../llvm
        fi
      fi
    fi
    if [[ "$NINAJABUILD" = [yY] ]]; then
      ln -s $PWD/compile_commands.json ../llvm
      time ninja-build${MAKETHREADS}
      time ninja-build check-all
      time ninja-build install
    else
      time make${MAKETHREADS}
      time make install
    fi
    echo
    find . -name "LLVMgold.so"
    echo "/opt/sbin/llvm-${v}/bin/clang -v"
    /opt/sbin/llvm-${v}/bin/clang -v
    echo
  done
}
######################################################
starttime=$(TZ=UTC date +%s.%N)
{
  yuminstall_llvm
  buildllvmgold
  buildllvm
  tidyup
  echo
  echo "-------------------------------------------------------------------"
  echo "/usr/local/bin/ld -v"
  /usr/local/bin/ld -v
  echo
  echo "/usr/local/bin/ld.gold -v"
  /usr/local/bin/ld.gold -v
  echo
  echo "/usr/local/bin/ld.bfd -v"
  /usr/local/bin/ld.bfd -v
  if [[ "$CLANG_ALL" = [yY] ]]; then
    echo
    echo "/opt/sbin/llvm-release_40/bin/clang -v"
    /opt/sbin/llvm-release_40/bin/clang -v
    echo
    echo "ls -lah /opt/sbin/llvm-release_40/lib/LLVMgold.so"
    ls -lah /opt/sbin/llvm-release_40/lib/LLVMgold.so
    echo
    echo "/opt/sbin/llvm-release_50/bin/clang -v"
    /opt/sbin/llvm-release_50/bin/clang -v
    echo
    echo "ls -lah /opt/sbin/llvm-release_50/lib/LLVMgold.so"
    ls -lah /opt/sbin/llvm-release_50/lib/LLVMgold.so
  else
    echo
    echo "/opt/sbin/llvm-${CLANG_RELEASE}/bin/clang -v"
    /opt/sbin/llvm-${CLANG_RELEASE}/bin/clang -v
    echo
    echo "ls -lah /opt/sbin/llvm-${CLANG_RELEASE}/lib/LLVMgold.so"
    ls -lah /opt/sbin/llvm-${CLANG_RELEASE}/lib/LLVMgold.so
  fi
  echo "-------------------------------------------------------------------"
  echo
  echo "tail -1 ${CENTMINLOGDIR}/centminmod_llvm_${DT}.log"
} 2>&1 | tee ${CENTMINLOGDIR}/centminmod_llvm_${DT}.log

endtime=$(TZ=UTC date +%s.%N)

INSTALLTIME=$(echo "scale=2;$endtime - $starttime"|bc )
echo "" >> ${CENTMINLOGDIR}/centminmod_llvm_${DT}.log
if [[ "$CLANG_ALL" = [yY] ]]; then
  echo "Total LLVM 4 & 5 Build Time: $INSTALLTIME seconds" >> ${CENTMINLOGDIR}/centminmod_llvm_${DT}.log
elif [[ "$CLANG_RELEASE" = 'release_40' ]]; then
  echo "Total LLVM 4 Build Time: $INSTALLTIME seconds" >> ${CENTMINLOGDIR}/centminmod_llvm_${DT}.log
elif [[ "$CLANG_RELEASE" = 'release_50' ]]; then
  echo "Total LLVM 5 Build Time: $INSTALLTIME seconds" >> ${CENTMINLOGDIR}/centminmod_llvm_${DT}.log
elif [[ "$CLANG_RELEASE" = 'release_60' ]]; then
  echo "Total LLVM 5 Build Time: $INSTALLTIME seconds" >> ${CENTMINLOGDIR}/centminmod_llvm_${DT}.log
elif [[ "$CLANG_RELEASE" = 'release_master' ]]; then
  echo "Total LLVM Master Branch Build Time: $INSTALLTIME seconds" >> ${CENTMINLOGDIR}/centminmod_llvm_${DT}.log
fi