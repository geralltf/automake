#! /bin/sh
# Copyright (C) 2012 Free Software Foundation, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Test and that vapi files are correctly handled by Vala support.

required='valac cc GNUmake'
. ./defs || Exit 1

set -e

cat >> configure.ac <<'END'
AC_PROG_CC
AM_PROG_CC_C_O
AM_PROG_VALAC([0.7.3])
AC_OUTPUT
END

cat > Makefile.am <<'END'
bin_PROGRAMS = zardoz
AM_VALAFLAGS = --profile=posix
zardoz_SOURCES = zardoz.vala foo.vapi foo.h
END

cat > zardoz.vala <<'END'
int main ()
{
    stdout.printf (BARBAR);
    return 0;
}
END

echo '#define BARBAR "Zardoz!\n"' > foo.h

cat > foo.vapi <<'END'
[CCode (cprefix="", lower_case_cprefix="", cheader_filename="foo.h")]
public const string BARBAR;
END

if cross_compiling; then :; else
  unindent >> Makefile.am <<'END'
    check-local: test2
    .PHONY: test1 test2
    test1:
	./zardoz
	./zardoz | grep 'Zardoz!'
    test2:
	./zardoz
	./zardoz | grep 'Quux!'
END
fi

$ACLOCAL
$AUTOMAKE -a
$AUTOCONF

./configure --enable-dependency-tracking

$MAKE
ls -l        # For debugging.
cat zardoz.c # Likewise.
grep 'BARBAR' zardoz.c
$MAKE test1

# Simple check on remake rules.
$sleep
echo '#define BAZBAZ "Quux!\n"' > foo.h
sed 's/BARBAR/BAZBAZ/' zardoz.vala > t && mv -f t zardoz.vala || Exit 99
$MAKE && Exit 1
sed 's/BARBAR/BAZBAZ/' foo.vapi > t && mv -f t foo.vapi || Exit 99
$MAKE
cat zardoz.c # For debugging.
grep 'BAZBAZ' zardoz.c
$MAKE test2

# Check the distribution.
$MAKE distcheck

: