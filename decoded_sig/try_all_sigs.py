import sys
import subprocess

prak_list = ['PRAK-2018-01', 'PRAK-2020-01', 'PRAK-2019-09', 'PRAK-2017-12', 'PRAK-2017-08', 'PRAK-2017-01']
tbie_list = ['TBIE-2021-06', 'TBIE-2020-04', 'TBIE-2019-11', 'TBIE-2018-07']


for i in prak_list:
    for j in tbie_list:
        subprocess.run(["python3", "../../dji-firmware-tools/dji_imah_fwsig.py", "-vv", "-k", i, "-k", j, "-u", "-i", sys.argv[1]])




