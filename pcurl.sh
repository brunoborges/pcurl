#!/bin/bash
#title           :pcurl.sh
#description     :This script will download a file in segments.
#author		 :Phil Rumble prumble@au1.ibm.com
#date            :20120202
#version         :0.1    
#usage		 :bash pcurl.sh url
#notes           :Install curl to use this script.


debug() { echo "DEBUG: $*" >&2; }


waitall() { # PID...
  ## Wait for children to exit and indicate whether all exited with 0 status.
  local errors=0
  while :; do
    #debug "Processes remaining: $*"
    for pid in "$@"; do
      shift
      if kill -0 "$pid" 2>/dev/null; then
        #debug "$pid is still alive."
        set -- "$@" "$pid"
      elif wait "$pid"; then
        debug "$pid exited with zero exit status."
      else
        debug "$pid exited with non-zero exit status."
        ((++errors))
      fi
    done
    (("$#" > 0)) || break
    # TODO: how to interrupt this sleep when a child terminates?
    sleep ${WAITALL_DELAY:-1}
   done
  ((errors == 0))
}


URL=$1
FILENAME=`basename $URL`

echo "Downloading ${URL}"

#curl -s -I ${URL} 
#FILESIZE=`curl -s -I ${URL} | cut -s -f 2 -d ':' | tail -2 | xargs echo | awk '{print $1}'`
#FILEINFO=`curl -s -I ${URL}` 
#echo ${FILEINFO}
#FILESIZE=`curl -s -I ${URL}| tail -3 | head -2 | awk '{print $2}'`
#echo ${FILESIZE}

FILESIZE_TXT="./FILESIZE.txt"
curl -s -I ${URL} > ${FILESIZE_TXT}
i="0"

FILESIZE="0"

while read myline
do
	#echo $i $myline
	#if [ "$i" ==  "7" ]
	#then
#		echo $i $myline
	#fi
	if [[ "$myline" == Content-Length* ]]
	then
		#echo $i $myline
		FILESIZE=${myline:16}
		#echo ".${FILESIZE}."
 		FILESIZE=${FILESIZE//[^0-9]/}
		#echo ".${FILESIZE}."
	fi
	i=`expr $((${i} + 1))`
done < ${FILESIZE_TXT}

rm -f ${FILESIZE_TXT}

#TODO Add exit at this point if this previous step fails.

echo "flsize is ${FILESIZE} bytes"

MAX_SEGMENTS=10

SEGMENT_SIZE=`expr $((${FILESIZE} / ${MAX_SEGMENTS}))`

echo "SEGMENT_SIZE is set to ${SEGMENT_SIZE}"

START_SEG=0;
END_SEG=${SEGMENT_SIZE}
pids=""
for i in $(eval echo {1..${MAX_SEGMENTS}})
do
	if [ "$i" !=  "$MAX_SEGMENT" ]
	then 
		curl -s --range ${START_SEG}-${END_SEG} -o ${FILENAME}.part${i} ${URL} &
		pids="$pids $!"
	else
		curl -s --range ${START_SEG}- -o ${FILENAME}.part${i} ${URL} &
		pids="$pids $!"
	fi
	echo "Start = ${START_SEG}"
	echo "End = ${END_SEG}"
	START_SEG=$((${END_SEG}+1))
	END_SEG=$((${START_SEG}+${SEGMENT_SIZE}))
done
	#echo "Start = ${START_SEG}"
	#curl -s --range ${START_SEG}- -o ${FILENAME}.part10 ${URL} &
	#pids="$pids $!"

	waitall $pids
	echo "Download of segments is completed"

i=1
for i in $(eval echo {1..${MAX_SEGMENTS}})
do
	if [ "$i" == 1 ]
	then
		#echo "building segment:${i}"
		cat ${FILENAME}.part${i} > ${FILENAME}
	else
		#echo "building segment:${i}"
		cat ${FILENAME}.part${i} >> ${FILENAME}
	fi
done
for i in $(eval echo {1..${MAX_SEGMENTS}})
do
	rm -f ${FILENAME}.part${i} 
done
echo "Download of ${FILENAME} is complete"
