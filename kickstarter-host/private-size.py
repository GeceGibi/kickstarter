#!/usr/bin/python3
# Prints the bytes that deleting the given files or folders would free.
# An APFS clone shares blocks with its source, so du shows the whole base image.
# getattrlist ATTR_CMNEXT_PRIVATESIZE counts only the blocks this file owns.
import ctypes
import os
import struct
import sys

ATTR_BIT_MAP_COUNT = 5
ATTR_CMN_RETURNED_ATTRS = 0x80000000
ATTR_CMNEXT_PRIVATESIZE = 0x00000008
FSOPT_NOFOLLOW = 0x00000001
FSOPT_ATTR_CMN_EXTENDED = 0x00000020


class AttrList(ctypes.Structure):
    _fields_ = [
        ("bitmapcount", ctypes.c_ushort),
        ("reserved", ctypes.c_uint16),
        ("commonattr", ctypes.c_uint32),
        ("volattr", ctypes.c_uint32),
        ("dirattr", ctypes.c_uint32),
        ("fileattr", ctypes.c_uint32),
        ("forkattr", ctypes.c_uint32),
    ]


libc = ctypes.CDLL(None, use_errno=True)
libc.getattrlist.argtypes = [
    ctypes.c_char_p,
    ctypes.POINTER(AttrList),
    ctypes.c_void_p,
    ctypes.c_size_t,
    ctypes.c_ulong,
]
request = AttrList(ATTR_BIT_MAP_COUNT, 0, ATTR_CMN_RETURNED_ATTRS, 0, 0, 0, ATTR_CMNEXT_PRIVATESIZE)
buf = ctypes.create_string_buffer(64)


def private_size(path):
    if libc.getattrlist(os.fsencode(path), ctypes.byref(request), buf, len(buf),
                        FSOPT_NOFOLLOW | FSOPT_ATTR_CMN_EXTENDED) != 0:
        return 0
    # u_int32 length, attribute_set_t returned (5 x u_int32), off_t privatesize
    fork_returned = struct.unpack_from("<I", buf, 20)[0]
    if not fork_returned & ATTR_CMNEXT_PRIVATESIZE:
        return 0
    return struct.unpack_from("<q", buf, 24)[0]


total = 0
for root in sys.argv[1:]:
    if os.path.isfile(root):
        total += private_size(root)
    for folder, _, files in os.walk(root):
        for name in files:
            total += private_size(os.path.join(folder, name))
print(total)

