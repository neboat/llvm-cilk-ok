#!/bin/bash

###### This file keeps the script to build Linux version of CilkPlus Clang based compiler

###### By default we assume you're using 'llvm' folder created in the current directory as a base folder of your source installation
###### If you use some specific location then pass it as argument to this script

###### By default we assume you're using 'llvm' folder created in the current directory as a base folder of your source installation
###### If you use some specific location then pass it as argument to this script

if [ "$1" = "" ]
then
  LLVM_NAME=llvm-cilk-ok
else
  LLVM_NAME=$1
fi

LLVM_HOME=`pwd`/"$LLVM_NAME"/src
LLVM_TOP=`pwd`/"$LLVM_NAME"

LLVM_GIT_REPO="git@github.mit.edu:supertech/llvm-cilk-ok.git"
LLVM_BRANCH="cilkplus"
CLANG_GIT_REPO="git@github.mit.edu:supertech/clang-cilk-ok.git"
CLANG_BRANCH=""
COMPILERRT_GIT_REPO="https://github.com/cilkplus/compiler-rt"
COMPILERRT_BRANCH="cilkplus"
# CILK_RT_GIT_REPO="https://bitbucket.org/intelcilkruntime/intel-cilk-runtime.git"
CILK_RT_GIT_REPO="git@github.mit.edu:SuperTech/cilkplus-rts-src.git"

echo Building $LLVM_HOME...

if [ ! -d $LLVM_HOME ]; then
    if [ "" != "$LLVM_BRANCH" ]; then
        git clone -b $LLVM_BRANCH $LLVM_GIT_REPO $LLVM_HOME
    else
        git clone $LLVM_GIT_REPO $LLVM_HOME
    fi
else
    cd $LLVM_HOME
    git pull --rebase
    cd -
fi

if [ ! -d $LLVM_HOME/tools/clang ]; then
    if [ "" != "$CLANG_BRANCH" ]; then
        git clone -b $CLANG_BRANCH $CLANG_GIT_REPO $LLVM_HOME/tools/clang
    else
        git clone $CLANG_GIT_REPO $LLVM_HOME/tools/clang
    fi
else
    cd $LLVM_HOME/tools/clang
    git pull --rebase
    cd -
fi

rm -rf $LLVM_HOME/projects/compiler-rt
if [ "" != "$COMPILERRT_BRANCH" ]; then
    git clone -b $COMPILERRT_BRANCH $COMPILERRT_GIT_REPO $LLVM_HOME/projects/compiler-rt
else
    git clone $COMPILERRT_GIT_REPO $LLVM_HOME/projects/compiler-rt
fi

BUILD_HOME=$LLVM_HOME/build
rm -rf $BUILD_HOME
mkdir -p $BUILD_HOME
cd $BUILD_HOME

set -e

###### If you need to tune your environment - do it
#export PATH=/usr/local/bin:/usr/bin:$PATH
#export LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH
echo ../configure --prefix="$LLVM_TOP"
../configure --prefix="$LLVM_TOP"
# ../configure --with-gcc-toolchain=/usr/local

###### By default you should simply lanch
#../configure

###### Now you're able to build the compiler
make -j8 >build.log
if [ "0" != "$?" ]; then
    >&2 echo "[$0 Error] Problem building $LLVM_NAME."
    exit 1
fi
make install

###### Produce a shell script, "usellvm.sh", to set up environment to
###### use llvm-cilk-ok.
echo export PATH=$LLVM_TOP/bin:'$PATH' > $LLVM_TOP/usellvm.sh
echo export LIBRARY_PATH=$LLVM_TOP/lib:'$LIBRARY_PATH' >> $LLVM_TOP/usellvm.sh
echo export LD_LIBRARY_PATH=$LLVM_TOP/lib:'$LD_LIBRARY_PATH' >> $LLVM_TOP/usellvm.sh
echo export C_INCLUDE_PATH=$LLVM_TOP/include:'$CPATH' >> $LLVM_TOP/usellvm.sh
echo export CPLUS_INCLUDE_PATH=$LLVM_TOP/include:'$CPATH' >> $LLVM_TOP/usellvm.sh

###### The following lines will prepare your system to build CilkPlus runtime
###### If you don't want to do it - simply finish the script here
###### (remove or comment all the rest lines of the script)
###### We're suggesting to use your own Clang version to build the runtime
###### that's why we're exporting the following 3 variables
echo source $LLVM_TOP/usellvm.sh
source $LLVM_TOP/usellvm.sh
export CC=clang
export CXX=clang++

# ###### That's the standard place in the llvm structure to deal with cilk runtime library
# ###### We're getting the latest sources from Cilk runtime site
# ###### that's why we suggest to remove all the stuff from our own code snapshot in the source tree
# rm -rf $CILK_RT_HOME
# git clone https://bitbucket.org/intelcilkruntime/intel-cilk-runtime.git $CILK_RT_HOME
# cd $CILK_RT_HOME

###### Grab the Cilk runtime system, then build it
CILK_RT_HOME=$LLVM_TOP/cilkrts
rm -rf $CILK_RT_HOME
git clone $CILK_RT_GIT_REPO $CILK_RT_HOME
cd $CILK_RT_HOME

###### You could find the instruction on how to build cilk runtime in $CILK_RT_HOME/README
libtoolize
aclocal
automake --add-missing
autoconf

###### By default we'll install libraries and include files in $BUILD_HOME
###### If you don't like it - remove --prefix or use your prefered location
./configure --prefix=$LLVM_TOP

make -j7
make install

###### That's it!
###### But don't forget to extend LD_LIBRARY_PATH and INCLUDE search path with selected --prefix/lib|include
###### (if you used the one). For example:
###### export LD_LIBRARY_PATH=$BUILD_HOME/lib:$LD_LIBRARY_PATH
###### export CFLAGS=$BUILD_HOME/include:$CFLAGS
###### export CXXFLAGS=$BUILD_HOME/include:$CXXFLAGS
