LS-DOS 6.3.1 for Model II/12/16 Build System
============================================

First get the tools needed to build the system disk images:
- Run `get_trs80gp.sh` to download the [TRS80gp](http://48k.ca) emulator from George Phillips
- Run `get_hxcfe.sh` to download the [HxC Floppy Emulator softwate](https://hxc2001.com/download/floppy_drive_emulator/)
  from Jean-Francois Del Nero (HxC2001).



How-to
------

### 0. If necessary, convert the source, JCL and text files from DOS to Unix format.

- Run: `DOS2UNIX.BAT`.
- Attention: running that procedure twice can render the files unusable.


### 1. Create 1-sided LS-DOS 6.3.1A floppy image from TRS80gp internal image

- Input:
  - :0 = `:ld2` from TRS80gp = LS-DOS 6.3.1 Level-1A (last known official build)
  - :1 = `:lu2` from TRS80gp = FreHD utilities (VHDUTL, IMPORT2 and EXPORT2)
- Output: 
  - `l2-631a.dmk` = LS-DOS 6.3.1 Level-1A (1-sided)
  - `m2-lsdos-util` = FreHD utilities
- Action:
  - Formats a new bootable one-sided LS-DOS 6.3.1 System Disk. This disk will be
    used to create the new LS-DOS disk `L631NEW2.DSK` in step 6.
- Run: `MAKEBOOT_631A_1S.BAT`


### 2. Create 2-sided LS-DOS 6.3.1A floppy image from TRS80gp internal image

- Input:
  - :0 = `:ld2` from TRS80gp = LS-DOS 6.3.1 Level-1A (last known official build)
  - :1 = `:lu2` from TRS80gp = FreHD utilities (VHDUTL, IMPORT2 and EXPORT2)
- Output:
  - `l2-631a-ds.dmk` = LS-DOS 6.3.1 Level-1A (2-sided)
  - `m2-lsdos-util` = FreHD utilities
- Action:
  - Formats a new bootable two-sided LS-DOS 6.3.1 System Disk. This disk will be
    used to create the build system disk `L631BOOT_631A.DSK` in step 4.
- Run: `MAKEBOOT_631A_2S.BAT`


### 3. Create Build System Boot Disk [L631BOOT] using LS-DOS 6.3.1A

- Input:
  - :0 = `l2-631a-ds.dmk` = LS-DOS 6.3.1 Level-1A (2-sided)
  - :1 = `m2-lsdos-util` or `:lu2` = FreHD utilities
- Output: 
  - `L631BOOT_631A.DSK` = Build System Boot Disk [L631BOOT]
    - System files: Original
    - New files: Build utilities and IMPORT/EXPORT JCL files
- Action:
  - Create `L631BOOT_631A.DSK` as a copy of `l2-631a-ds.dmk`
  - Import Build utilities and IMPORT/EXPORT JCL files to `:0`
- Run: `MAKE_L631BOOT_631A.BAT`
  - Close the window when job is done.


### 4. Create Build Data Disks [L631UTL2] [L631SYS2] [L631BIN2]

- Input:
  - :0 = `l2-631a-ds.dmk` = LS-DOS 6.3.1 Level-1A (2-sided)
  - :1 = `m2-lsdos-util` or `:lu2` = FreHD utilities
- Output: 
  - `L631UTL2.DSK` = Utilities Disk [L631UTL2]
    - New files: Utilities /ASM files, /DAT files, /FIX file
  - `L631SYS2.DSK` = System Files Disk [L631SYS2]
    - New files: System /ASM files
  - `L631BIN2.DSK` = Binary Files Disk [L631BIN2]
- Action:
  - Create `L631BOOT_631A.DSK` as a copy of `l2-631a-ds.dmk`
  - Import Build utilities and IMPORT/EXPORT JCL files to `:0`
- Run: `MAKE_L631DATA_631A.BAT`
  - Close the window when job is done.


### 5. Build LS-DOS 6.3.1 CMD Files using LS-DOS 6.3.1A

- Input:
  - :0 = `L631BOOT_631A.DSK` = Build System Boot Disk [L631BOOT]
  - :1 = `L631UTL2.DSK` = Utilities Disk [L631UTL2]
  - :2 = `L631SYS2.DSK` = System Files Disk [L631SYS2]
  - :3 = `L631BIN2.DSK` = Binary Files Disk [L631BIN2]
- Output:
  - :3 = `L631BIN2.DSK` = Binary Files Disk [L631BIN2]
    - New files: New /CMD files from the /ASM files.
- Action:
  - Do a build of the /CMD files that will be used to create
    new LS-DOS System Disks.
  - Optionally export the assembly listing /PRN files.
- Run: `BUILD2_631A.BAT`
  - In the emulator:
    - Do `TED BUILDVER/ASM` Modify the file `BUILDVER/ASM:1` to change the DOS version
      and build level (note that `TAB`s are not shown correctly on screen):
      - `@DOSVER EQU 631` to select LS-DOS version 6.3.1;
      - `@DOSLVL EQU 'N'` to select LS-DOS Build Level. For 6.3.1, levels A to H support
        dates to 2011 - levels L and above support dates to 2079. Level N fixes bugs
        related to a missing stack pointer relocation in the keyboard and timer interrupt
        handlers;
      - Press `CTRL`-`F` and type `BUILDVER/ASM` to save the updated file;
      - Press `ESC` then `=` followed by `ENTER` to exit TED.
    - Run: `DO BUILD` to build the /CMD files with assembly
      listing output to /PRN files (exported). Build time: ca. ?? minutes.
    - Run: `DO BUILDNL` to build the /CMD files without assembly
      listing output (faster). Build time: ca. 10 minutes.


### 6. Make LS-DOS 6.3.1 System Disk [L631NEW2] using LS-DOS 6.3.1A

- Input: 
  - :0 = `L631BOOT_631A.DSK` = Build System Boot Disk [L631BOOT]
  - :1 = `L631UTL2.DSK` = Utilities Disk [L631UTL2]
  - :2 = `L631NEW2.DSK` = New copy of `l2-631a.dmk`, will get the new version
    of the DOS System Files and Utilities
  - :3 = `L631BIN2.DSK` = Binary Files Disk [L631BIN2]
- Output:
  - :2 = `L631NEW2.DSK` = Bootable 1-sided floppy with the new DOS System files
    and utilities, disk date is `11/11/11`.
    - New files: New /SYS, /CMD, /DCT, /DVR, /FLT files, with date `11/11/11`.
- Action:
  - Copy all /CMD files on :3 to replace existing contents of
    /SYS, /CMD, /DCT, /DVR, /FLT files on :2, with date `11/11/11`.
- Run: `GET2_631A.BAT`.


### 7. Test the new LS-DOS 6.3.1 System Disk [L631NEW2]

- Input:
  - :0 = `L631NEW2.DSK` = Bootable one-sided floppy with the new DOS System files
    and utilities, disk date is `11/11/11`.
- Run: `TEST2.BAT`.


### 8: Create 1-sided LS-DOS 6.3.1N floppy image from new build (optional)

- Input:
  - :0 = `L631NEW2.DSK` = Bootable one-sided floppy with the new DOS System files
    and utilities, disk date is `11/11/11`.
  - :1 = `m2-lsdos-util` or `:lu2` = FreHD utilities
- Output:
  - `l2-631n.dmk` = LS-DOS 6.3.1 Level-1N (1-sided) Disk date: current;
    DOS files date: `11/11/11`.
  - `l2-631n.hfe` = HFE version of `l2-631n.dmk` to run on real Model II hardware
    with a GOTEK or HxC Floppy Emulator.
  - `m2-lsdos-util` = FreHD utilities
- Action:
  - Formats a new bootable one-sided LS-DOS 6.3.1 System Disk. This disk will be
    used to create the new LS-DOS disk `L631NEW2.DSK` in step ??.
- Run: `MAKEBOOT_631N_1S.BAT`


### 9. Create 2-sided LS-DOS 6.3.1N floppy image from new build

- Input:
  - :0 = `L631NEW2.DSK` = Bootable one-sided floppy with the new DOS System files
    and utilities, disk date is `11/11/11`.
  - :1 = `:lu2` from TRS80gp = FreHD utilities (VHDUTL, IMPORT2 and EXPORT2)
- Output:
  - `l2-631n-ds.dmk` = LS-DOS 6.3.1 Level-1N (2-sided). Disk date: current;
    DOS files date: `11/11/11`.
  - `l2-631n-ds.hfe` = HFE version of `l2-631n-ds.dmk` to run on real Model II hardware
    with a GOTEK or HxC Floppy Emulator.
  - `m2-lsdos-util` = FreHD utilities
- Action:
  - Formats a new bootable two-sided LS-DOS 6.3.1 System Disk. This disk will be
    used to create the build system disk `L631BOOT_631N.DSK` in step 4.
- Run: `MAKEBOOT_631N_2S.BAT`


### 10. Create Build System Boot Disk [L631BOOT] using LS-DOS 6.3.1N

- Input:
  - :0 = `l2-631n-ds.dmk` = LS-DOS 6.3.1 Level-1N (2-sided)
  - :1 = `m2-lsdos-util` or `:lu2` = FreHD utilities
- Output: 
  - `L631BOOT_631N.DSK` = Build System Boot Disk [L631BOOT]
    - System files: Original
    - New files: Build utilities and IMPORT/EXPORT JCL files
- Action:
  - Create `L631BOOT_631N.DSK` as a copy of `l2-631a-ds.dmk`
  - Import Build utilities and IMPORT/EXPORT JCL files to `:0`
- Run: `MAKE_L631BOOT_631N.BAT`
  - Close the window when job is done.


### 11. Build LS-DOS 6.3.1 CMD Files using new LS-DOS build [l2-631n-ds.dmk] (optional)

- Input:
  - :0 = `L631BOOT_631N.DSK` = Build System Boot Disk [L631BOOT]
  - :1 = `L631UTL2.DSK` = Utilities Disk [L631UTL2]
  - :2 = `L631SYS2.DSK` = System Files Disk [L631SYS2]
  - :3 = `L631BIN2.DSK` = Binary Files Disk [L631BIN2]
- Output:
  - :3 = `L631BIN2.DSK` = Binary Files Disk [L631BIN2]
    - New files: New /CMD files from the /ASM files.
- Action:
  - Do a build of the /CMD files that will be used to create
    new LS-DOS System Disks.
  - Optionally export the assembly listing /PRN files.
- Run: `BUILD2_631N.BAT`
  - See step 5.


### 12. Make LS-DOS 6.3.1 System Disk [L631NEW2] using new LS-DOS build [l2-631n-ds.dmk]

- Input: 
  - :0 = `L631BOOT_631N.DSK` = Build System Boot Disk [L631BOOT]
  - :1 = `L631UTL2.DSK` = Utilities Disk [L631UTL2]
  - :2 = `L631NEW2.DSK` = New copy of `l2-631a.dmk`, will get the new version
    of the DOS System Files and Utilities
  - :3 = `L631BIN2.DSK` = Binary Files Disk [L631BIN2]
- Output:
  - :2 = `L631NEW2.DSK` = Bootable 1-sided floppy with the new DOS System files
    and utilities, disk date is `11/11/11`.
    - New files: New /SYS, /CMD, /DCT, /DVR, /FLT files, with current date.
- Action:
  - Copy all /CMD files on :3 to replace existing contents of
    /SYS, /CMD, /DCT, /DVR, /FLT files on :2, with current date.
- Run: `GET2_NEW.BAT`.


### 13. Test the new LS-DOS 6.3.1 System Disk [L631NEW2]

- Input:
  - :0 = `L631NEW2.DSK` = Bootable one-sided floppy with the new DOS System files
    and utilities, disk date is '11/11/11' and DOS files date is current.
- Run: `TEST2.BAT`.


### 14. Create 1-sided and 2-sided LS-DOS 6.3.1N floppy images from new build (final)

- Repeat steps 8 and 9 to create the final 1-sided and 2-sided floppy images.
- Output:
  - `l2-631n.dmk` = LS-DOS 6.3.1 Level-1N (1-sided). Disk date: current;
    DOS files date: current.
  - `l2-631n-ds.dmk` = LS-DOS 6.3.1 Level-1N (2-sided). Disk date: current;
    DOS files date: current.
