#!/bin/ksh

if [ -x /usr/xpg4/bin/id ]
then
        id=`/usr/xpg4/bin/id -u`
else
        id=`/usr/bin/id -u`
fi

if [ $id -ne 0 ]
then
        echo "You must be root to execute this command"
        exit 1
fi


OLDPWD=`pwd`
cd `dirname $0`
BASEDIR=`pwd`
BASEDIR=`dirname $BASEDIR`
cd $OLDPWD

print "What is your basedirectory [default=$BASEDIR]: \c"
read basedir
basedir=${basedir:-$BASEDIR}

print "choose tar.Z filename [default=/tmp/IPmanage.tar.Z]: \c"
read tarfile
tarfile=${tarfile:-/tmp/IPmanage.tar.Z}

tmpfile1=/tmp/`basename $0`.$$_1
tmpfile2=/tmp/`basename $0`.$$_2
tmpfile3=/tmp/`basename $0`.$$_3
exclude=/tmp/`basename $0`.$$_exclude
rm -f ${tmpfile1} ${tmpfile2} ${tmpfile3} ${exclude}

cd $BASEDIR
find . -name "*.old*" -print >${tmpfile1}

### excludes
cat - <<- %EOF >>${tmpfile2}
./files/passwords
./modules/ipmanage_config.pm*
./index.html
./DEVELOP
./log
%EOF


find `cat ${tmpfile1} ${tmpfile2}` -print >${tmpfile3}
cat ${tmpfile3} | grep -v "\/examples" >${exclude}

tar chvXf ${exclude} - . | compress >$tarfile

rm -f ${tmpfile1} ${tmpfile2} ${tmpfile3} ${exclude}
cd $OLDPWD

echo "Distribution is in $tarfile"
