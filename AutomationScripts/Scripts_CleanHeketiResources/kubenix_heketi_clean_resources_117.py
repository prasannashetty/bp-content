import os
import time

vg_name = "vg_27514e0c4282a0b851461f4aaa4241fb"
initial_bricks=os.popen("lvs --options=lv_name | grep -i brick")
total_bricks = []
for brk in initial_bricks.readlines():
	total_bricks.append(brk.strip(' \n'))
print(total_bricks)
print(len(total_bricks))
except_bricks = {'brick_8f07f6e9d61c99226017b51cd83b70fa', 'brick_b87433ddd6903e7dd541dfcaf1166d11'}

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
	
