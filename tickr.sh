#!/bin/sh

# FIXME init random seed
# FIXME get year from the net

# as a simple hack only pics from 2005-2007 will be taken in 2008
# con: this year's pics will never show up
# pro: we don't need to rely on localtime (works in 1970, too :)

# THIS_YEAR=4 # 2009
# THIS_YEAR=5 # 2010
# THIS_YEAR=6 # 2011
# THIS_YEAR=7 # 2012
# THIS_YEAR=8 # 2013
# THIS_YEAR=9 # 2014
# THIS_YEAR=10 # 2015
# THIS_YEAR=11 # 2016
# THIS_YEAR=12 # 2017
# THIS_YEAR=13 # 2018
# THIS_YEAR=14 # 2019
# THIS_YEAR=15 # 2020
# THIS_YEAR=16 # 2021
# THIS_YEAR=17 # 2022
# THIS_YEAR=18 # 2023
# THIS_YEAR=19 # 2024
# THIS_YEAR=20 # 2025
# THIS_YEAR=21 # 2026
# THIS_YEAR=22 # 2027
# THIS_YEAR=23 # 2028
# THIS_YEAR=24 # 2029
# THIS_YEAR=25 # 2030
# THIS_YEAR=26 # 2031
# THIS_YEAR=27 # 2032

THIS_YEAR=8

SCREEN_X=1280
SCREEN_Y=1024

LIMIT_RATE=100k

HIST=235 # how many pics on the html page

REMOTE_PIC=/tmp/remote.jpg
REMOTE_TAG=/tmp/remote.tag

WGET="/usr/bin/wget"

TMP_HTML=/tmp/tickr_tmp.html

# for fbi
export FRAMEBUFFER=/dev/fb0

# switch off cursor blink
echo -e '\033[?17c'
setterm -blank 0


# array workaround/helper functions
# (arrays are not part of POSIX shell)
aset() {
	eval "$1_$2=\$3"
}
aget() {
	eval "REPLY=\${${1}_${2}}"
}

#declare -a h_thumb[$HIST]
#declare -a h_large[$HIST]
#declare -a h_scale[$HIST]
#declare -a h_detail[$HIST]
##declare -a h_list[$HIST]

H_HEAD='
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html><head><title>tickr</title>
<style type="text/css"> <!-- A:link {text-decoration: none;color:#aaaaaa} A:visited {text-decoration: none;color:#777777} A:active {text-decoration: none} A:hover {text-decoration: none;color:#FFFFFF;background-color:#222222} --> </style>
</head><body bgcolor="#444444"><center>recent pictures<br><br>
<table>'
H_FOOT='</table></center></body></html>'


while true ; do
DONE=0
while [ "$DONE" != "1" ] ; do

	YEAR=$(( 2005 + $RANDOM % $THIS_YEAR ))
	DAY=$((     1 + $RANDOM % 31 ))
	MONTH=$((   1 + $RANDOM % 12 ))

	# leading zeros
	DAY=`printf "%02d" $DAY`
	MONTH=`printf "%02d" $MONTH`

	PIC_URL_LIST=http://flickr.com/explore/$YEAR/$MONTH/$DAY

	$WGET -q --limit-rate=$LIMIT_RATE $PIC_URL_LIST -O /tmp/flickr.html
	RET=$?
	if [ $RET != 0 ] ; then
		continue
	fi

	sed -nre 's@"@\n@gp;' /tmp/flickr.html | sed -nre 's@\\\/@\/@gp;' > /tmp/flickr.chopped

	PIC_COUNT=`sed -nre '/^http.*_m\.jpg/p' /tmp/flickr.chopped | wc -l`

	# sometimes we only get a partial page...
	if [ $PIC_COUNT == 0 ] ; then
		continue
	fi

	# choose a random pic from $PIC_URL_LIST
	PIC=$((     1 + $RANDOM % $PIC_COUNT ))

	PIC_URL=`sed -nre '/^http.*_m\.jpg/p' /tmp/flickr.chopped | sed -nre "${PIC}p"`
	PIC_URL_THUMB=$PIC_URL

	PIC_ID=`echo $PIC_URL | sed -nre 's@.*/([^_]*)_.*@\1@p'`

	PIC_DETAIL="http://www.flickr.com`sed -nre "/^\/photos.*$PIC_ID/{p;q;}" /tmp/flickr.chopped`"

	PIC_URL_LARGE=`sed -nre "/^http.*$PIC_ID.*_o.jpg/{p;q;}" /tmp/flickr.chopped`

	# fallback in case there's no .*_o.jpg
	if [ "$PIC_URL_LARGE" == "" ] ; then
		PIC_URL_LARGE=`sed -nre "/^http.*${PIC_ID}_[^_]*.jpg/{p;q;}" /tmp/flickr.chopped`
		if [ "$PIC_URL_LARGE" == "" ] ; then
			continue
		fi
	fi

	$WGET -q --limit-rate=$LIMIT_RATE $PIC_URL_LARGE -O /tmp/flickr_tmp.jpg

	RET=$?
	if [ $RET != 0 ] ; then
		continue
	fi

	x=`/bin/jpegsize -x /tmp/flickr_tmp.jpg`
	RET=$?
	if [ $RET != 0 ] ; then
		continue
	fi

	y=`/bin/jpegsize -y /tmp/flickr_tmp.jpg`
	RET=$?
	if [ $RET != 0 ] ; then
		continue
	fi

	mp=`/bin/jpegsize -m /tmp/flickr_tmp.jpg`
	RET=$?
	if [ $RET != 0 ] ; then
		continue
	fi

	FACTOR_X=$(( $x / $SCREEN_X ))
	FACTOR_Y=$(( $y / $SCREEN_Y ))
	FACTOR=1
	if [ $FACTOR_X -lt $FACTOR_Y ] ; then
		FACTOR=$FACTOR_X
	else
		FACTOR=$FACTOR_Y
	fi

	case "$FACTOR" in
		[23])
			SCALE=1/2
			djpeg -scale $SCALE -maxmemory 1024 -outfile /tmp/flickr.jpg /tmp/flickr_tmp.jpg 
			;;
		[4567])
			SCALE=1/4
			djpeg -scale $SCALE -maxmemory 1024 -outfile /tmp/flickr.jpg /tmp/flickr_tmp.jpg 
			;;
		[89])
			SCALE=1/8
			djpeg -scale $SCALE -maxmemory 1024 -outfile /tmp/flickr.jpg /tmp/flickr_tmp.jpg 
			;;
		#FIXME 10, 11, 12
		*)
			mv /tmp/flickr_tmp.jpg /tmp/flickr.jpg
			;;
	esac

	for i in `seq  $HIST -1 1` ; do

		aget h_thumb  $(( $i - 1 ))
		t_thumb=$REPLY
		aget h_large  $(( $i - 1 ))
		t_large=$REPLY
		aget h_scale  $(( $i - 1 ))
		t_scale=$REPLY
		aget h_detail $(( $i - 1 ))
		t_detail=$REPLY

		aset h_thumb  $i ${t_thumb}
		aset h_large  $i ${t_large}
		aset h_scale  $i "${t_scale}"
		aset h_detail $i ${t_detail}

		# no arrays in POSIX shells
		#h_thumb[$i]=${h_thumb[$(( $i - 1 ))]}
		#h_large[$i]=${h_large[$(( $i - 1 ))]}
		#h_scale[$i]=${h_scale[$(( $i - 1 ))]}
		#h_detail[$i]=${h_detail[$(( $i - 1 ))]}
	done

	aset h_list   0 $PIC_URL_LIST
	aset h_thumb  0 $PIC_URL_THUMB
	aset h_large  0 $PIC_URL_LARGE
	aset h_scale  0 "$x*$y, $mp MP"
	aset h_detail 0 $PIC_DETAIL

	# no arrays in POSIX shells
	#h_thumb[0]=$PIC_URL_THUMB
	#h_large[0]=$PIC_URL_LARGE
	#h_scale[0]="$x*$y, $mp MP"
	#h_detail[0]=$PIC_DETAIL

	DONE=1
done


# generate html output

echo $H_HEAD > ${TMP_HTML}

for i in `seq  0 $HIST` ; do

	aget h_list   $i
	t_list=$REPLY
	aget h_thumb  $i
	t_thumb=$REPLY
	aget h_large  $i
	t_large=$REPLY
	aget h_scale  $i
	t_scale=$REPLY
	aget h_detail $i
	t_detail=$REPLY

	echo "<tr>" >> ${TMP_HTML}
	echo "	<td>" >> ${TMP_HTML}
	echo "	<a href=\"${t_large}\"><img src=\"${t_thumb}\" border=\"0\" alt=\"pic$i\"></a>" >> ${TMP_HTML}
	echo "	</td><td>" >> ${TMP_HTML}
	echo "	&nbsp;&nbsp;&nbsp;<a href=\"${t_large}\">this pic in large</a> <font size=\"-2\">${t_scale}</font><br>" >> ${TMP_HTML}
	echo "	&nbsp;&nbsp;&nbsp;<a href=\"${t_detail}\">more details on this pic</a><br>" >> ${TMP_HTML}
	echo "	</td>" >> ${TMP_HTML}
	echo "</tr>" >> ${TMP_HTML}
done

echo $H_FOOT >> ${TMP_HTML}

mv ${TMP_HTML} /tmp/index.html

# see if someone remotely pushed a pic to show...
if [ -e $REMOTE_TAG ] ; then
	rm -f $REMOTE_TAG
	SHOW_PIC=$REMOTE_PIC
else
	SHOW_PIC=/tmp/flickr.jpg
fi

#killall fbskate
#/bin/fbskate $SHOW_PIC &

#killall ee
#/usr/bin/ee $SHOW_PIC/tmp/flickr.jpg &

#killall feh &> /dev/null
#/usr/bin/feh --full-screen --auto-zoom --borderless --hide-pointer $SHOW_PIC &> /dev/null &
#/usr/bin/feh                                                       $SHOW_PIC &

/bin/fbi -a $SHOW_PIC

done
