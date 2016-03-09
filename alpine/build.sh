#!/bin/sh

apk add -U alpine-sdk git build-base make automake autoconf libtool python-dev zlib-dev curl-dev apr-util-dev subversion-dev cyrus-sasl-crammd5 fts-dev openjdk8 linux-headers

cd ~
wget http://mirrors.advancedhosters.com/apache/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz
tar zxf apache-maven-3.3.9-bin.tar.gz
ln -s /root/apache-maven-3.3.9/bin/mvn /usr/bin/mvn

git clone https://git-wip-us.apache.org/repos/asf/mesos.git
cd mesos
git remote add jim https://github.com/jimfcarroll/mesos-on-alpine.git
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
git remote update

# pick off the top commit since that's where the patch is
PATCH=`git log jim/alpine | head | grep commit | head -1 | sed "s/commit //g"`

# if there's a tag or branch to build from, then switch to it
if [ "$1" != "" ]; then
    git checkout $1

    if [ $? -ne 0 ]; then
        echo "FAILED TO SWITCH TO BRANCH/TAG $1!"
        exit 1
    fi
fi

git cherry-pick $PATCH
if [ $? -ne 0 ]; then
    echo "FAILED to apply the patch at $PATCH"
    exit 1
fi

export JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk

./bootstrap

mkdir build
cd build

../configure --enable-alpine

# need to hack time.h
if [ ! -f /usr/include/time_orig.h ]; then
    mv /usr/include/time.h /usr/include/time_orig.h
    echo '#include<time_orig.h>' > /usr/include/time.h
    echo '#include<sys/time.h>' >> /usr/include/time.h
fi

NUMPROCS=`cat /proc/cpuinfo | egrep -e "^processor" | wc -l`

make -j$NUMPROCS
