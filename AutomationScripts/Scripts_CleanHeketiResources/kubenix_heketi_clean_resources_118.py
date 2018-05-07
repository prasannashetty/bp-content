import os
import time

vg_name = "vg_0cefc1046a035767f38e2b9f451cb141"
initial_bricks=os.popen("lvs --options=lv_name | grep -i brick")
total_bricks = []
for brk in initial_bricks.readlines():
	total_bricks.append(brk.strip(' \n'))
print(total_bricks)
print(len(total_bricks))
except_bricks = {'brick_7e1fedfd61478009f70a86fe16e58550', 'brick_e246bebf0dc929a12f8a769003a6dc14'}

final_bricks = set(total_bricks).difference(except_bricks)
print(list(final_bricks))
print(len(list(final_bricks)))

ids = []
for id in list(final_bricks) :
	print id.split('_')[1]
	ids.append(id.split('_')[1])
print(ids)
print(len(ids))

cnt=0
print(cnt)
for cmd in ids:
	#if(cnt==0):
	#	os.popen("fuser -ku /var/lib/heketi/mounts/" +vg_name+"/brick_"+cmd)
	#	time.sleep(10)
	#	cnt=cnt+1
	#	print("Count"+str(cnt))
	os.popen("umount /var/lib/heketi/mounts/" +vg_name+"/brick_"+cmd)
	os.popen("lvremove -y /dev/"+vg_name+"/tp_"+cmd)
	os.popen("rmdir /var/lib/heketi/mounts/" +vg_name+"/brick_"+cmd)

os.popen("killall glusterfsd ; killall -9 glusterfsd ; killall glusterd ; glusterd")
	
