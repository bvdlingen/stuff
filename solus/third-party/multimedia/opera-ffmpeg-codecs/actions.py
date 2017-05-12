#!/usr/bin/python

# Created For Solus Operating System

from pisi.actionsapi import get, pisitools, shelltools

NoStrip = ["/usr"]
IgnoreAutodep = True

# Should not change.
Suffix = "-1"

def setup():
    shelltools.system("pwd")
    shelltools.system("tar xvf opera-ffmpeg-codecs-%s%s-x86_64.pkg.tar.xz" % (get.srcVERSION(), Suffix))

def install():
    pisitools.insinto("/usr/lib64/opera/lib_extra", "usr/lib/opera/lib_extra/libffmpeg.so")
