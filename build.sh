#! /usr/bin/env bash
set -xe

export BASEDIR=$(dirname "$0")
export NAME="elastalert"
export VERSION="0.2.4"
export REVISION="1.el7"
export BUILDDIR="/tmp/build"
export INSTALLDIR="/usr/share/python"

yum -y update
yum -y install gcc make rpm-build openssl-devel libffi-devel
yum -y install epel-release
yum -y install python3
yum -y install python3-devel.x86_64
yum -y install centos-release-scl
pip3 install virtualenv-tools3
yum -y install python-virtualenv
yum -y install rh-ruby23 rh-ruby23-ruby-devel rh-ruby23-rubygems-devel rh-ruby23-rubygems
yum -y update
. /opt/rh/rh-ruby23/enable

gem install fpm --no-doc

rm -fr $BUILDDIR
mkdir -p $BUILDDIR$INSTALLDIR

# Configuration files
mkdir -p $BUILDDIR/etc/elastalert/rules
mkdir -p $BUILDDIR/etc/sysconfig/
cp $BASEDIR/conf/config.yml $BUILDDIR/etc/elastalert/.
cp $BASEDIR/conf/elastalert.sysconfig $BUILDDIR/etc/sysconfig/elastalert

# Unit file
mkdir -p $BUILDDIR/usr/lib/systemd/system
cp $BASEDIR/conf/elastalert.service $BUILDDIR/usr/lib/systemd/system

# Virtual Env

virtualenv -p python3 $BUILDDIR$INSTALLDIR/elastalert
$BUILDDIR$INSTALLDIR/elastalert/bin/pip3 install --upgrade pip 
$BUILDDIR$INSTALLDIR/elastalert/bin/pip3 install -r $BASEDIR/requirements.txt
$BUILDDIR$INSTALLDIR/elastalert/bin/pip3 install "elastalert==$VERSION"

find $BUILDDIR ! -perm -a+r -exec chmod a+r {} \;

cd $BUILDDIR$INSTALLDIR/elastalert
 virtualenv-tools --update-path $INSTALLDIR/elastalert
cd -


# Clean up
find $BUILDDIR -iname *.pyc -exec rm {} \;
find $BUILDDIR -iname *.pyo -exec rm {} \;

fpm -f \
    --iteration $REVISION \
    -t rpm -s dir -C $BUILDDIR -n $NAME -v $VERSION \
    --config-files "/etc/elastalert/config.yml" \
    --config-files "/etc/sysconfig/elastalert" \
    --config-files "/usr/lib/systemd/system/elastalert.service" \
    --rpm-tag 'Requires(pre): shadow-utils' \
    --rpm-tag 'Requires(post): systemd' \
    --rpm-tag 'Requires(preun): systemd' \
    --rpm-tag 'Requires(postun): systemd, shadow-utils' \
    --before-install $BASEDIR/scripts/preinstall.sh \
    --after-install $BASEDIR/scripts/postinstall.sh \
    --after-remove $BASEDIR/scripts/postuninstall.sh \
    --url http://elastalert.readthedocs.io/en/latest \
    --maintainer 'amine.benseddik@gmail.com' \
    --description 'ElastAlert - Easy & Flexible Alerting With Elasticsearch.' \
    --license 'Apache 2.0' \
    --package $BASEDIR \
    .

