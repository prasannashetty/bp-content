import os
import time

vg_name = "vg_c7bdae0fc4822d7bf916597ae649039d"
initial_bricks=os.popen("lvs --options=lv_name | grep -i brick")
total_bricks = []
for brk in initial_bricks.readlines():
	total_bricks.append(brk.strip(' \n'))
print(total_bricks)
print(len(total_bricks))
except_bricks = {'brick_b5adb8a83243426be0387e490987957f', 'brick_d3d6494bd0c2487e18f0b23a3e281466'}

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
	
