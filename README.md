K300 - Project @ Technion
=========================

**archive** - old firmware versions of DJI mini 2 SE that we extracted from the DJI Fly App and the drown itself (and verified by DankDrownDownloader), most files in format .fw.sig of DJI

**decoded_sig** - The decoded firmware files. The files were decoded using the code from dji_firmware_tools and the script try_all_sigs.py that is in the folder

**extracted_fs** - The partial file systems we extracted from the decoded sig files using binwalk

**lz4_decompress** - Some decoded file were found to be compressed lz4 files, these file were uncommpressed and are saves in this folder

**dji_network** - example file that wa extracted from the firmware filesystem and decompile it using IDA and Ghidra

## The Filesystems
### we extracted 2 full filesystems for 2 different firmware versions of the drown:
1. V01.02.0300_Mavic_Mini_2_dji_system
2. V01.03.0000_Mavic_Mini_2_dji_system

