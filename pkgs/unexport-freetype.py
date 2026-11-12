#!/usr/bin/env python3
"""Stop an executable's statically linked FreeType from interposing the system one.

ElegooSlicer links FreeType statically and exports its FT_* functions. Because the
executable comes first in the symbol lookup scope, the system fontconfig ends up
calling Elegoo's FT_New_Face but the system FT_Set_Named_Instance (which Elegoo's
copy lacks): a face from one FreeType handed to another, older/newer one, with a
different struct layout -> segfault while fontconfig scans a variable font.

The executable has no relocation against those symbols (it calls its copy
directly), so the exports only serve interposition. Renaming them in .dynstr
(same length, `FT_` -> `XT_`) makes lookups for `FT_*` miss the executable and
fall through to libfreetype. Nothing else in the binary changes.

Usage: unexport-freetype.py <elf>   (patched in place)
"""
import struct
import sys

PREFIX, REPLACEMENT = b"FT_", b"XT_"


def sections(data):
    (e_shoff,) = struct.unpack_from("<Q", data, 0x28)
    e_shentsize, e_shnum, e_shstrndx = struct.unpack_from("<HHH", data, 0x3A)
    raw = [struct.unpack_from("<IIQQQQIIQQ", data, e_shoff + i * e_shentsize) for i in range(e_shnum)]
    shstr_off = raw[e_shstrndx][4]

    def name(off):
        end = data.index(b"\0", shstr_off + off)
        return data[shstr_off + off:end].decode()

    return {name(s[0]): s for s in raw}


def main(path):
    data = bytearray(open(path, "rb").read())
    if data[:4] != b"\x7fELF" or data[4] != 2 or data[5] != 1:
        sys.exit(f"{path}: not a little-endian ELF64 file")
    secs = sections(data)
    dynsym, dynstr = secs[".dynsym"], secs[".dynstr"]
    sym_off, sym_size, sym_ent = dynsym[4], dynsym[5], dynsym[9]
    str_off = dynstr[4]

    names, targets = [], []
    for i in range(sym_size // sym_ent):
        st_name, _info, _other, st_shndx = struct.unpack_from("<IBBH", data, sym_off + i * sym_ent)
        start = str_off + st_name
        end = data.index(b"\0", start)
        names.append((start, end))
        if st_shndx != 0 and data[start:start + 3] == PREFIX:
            targets.append((start, end))
        elif st_shndx == 0 and data[start:start + 3] == PREFIX:
            sys.exit(f"{path}: imports {data[start:end].decode()}; refusing to rename")

    # Safety: the renamed bytes must not be shared with any other symbol name
    # (linkers may merge string tails).
    for t_start, t_end in targets:
        for n_start, n_end in names:
            if (n_start, n_end) != (t_start, t_end) and n_start < t_start + 3 and n_end > t_start:
                sys.exit(f"{path}: string at {t_start:#x} is shared; refusing to patch")

    if not targets:
        sys.exit(f"{path}: no exported {PREFIX.decode()}* symbol found (upstream changed?)")
    for start, _ in targets:
        data[start:start + 3] = REPLACEMENT
    open(path, "wb").write(data)
    print(f"{path}: un-exported {len(targets)} {PREFIX.decode()}* symbols")


if __name__ == "__main__":
    main(sys.argv[1])
