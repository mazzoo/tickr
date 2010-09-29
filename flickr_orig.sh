#!/bin/bash

# FIXME init random seed

# as a simple hack only pics from 2005-2007 will be taken in 2008
# con: this year's pics will never show up
# pro: we don't need to rely on localtime (works in 1970, too :)

# THIS_YEAR=4 # 2009
# THIS_YEAR=5 # 2010
# THIS_YEAR=6 # 2011
# THIS_YEAR=7 # 2012
# THIS_YEAR=8 # 2013
# THIS_YEAR=9 # 2014
THIS_YEAR=5

SCREEN_X=320
SCREEN_Y=240
SCREEN_X=1400
SCREEN_Y=1050


HIST=235 # how many pics on the html page
#HIST=7

declare -a h_thumb[$HIST]
declare -a h_large[$HIST]
declare -a h_scale[$HIST]
declare -a h_detail[$HIST]
declare -a h_list[$HIST]

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
	PAGE=$((    1 + $RANDOM % 50 ))
	PIC=$((     1 + $RANDOM % 10 ))

	PIC_URL_LIST=http://flickr.com/explore/interesting/$YEAR/$MONTH/$DAY/page$PAGE/

	wget -q $PIC_URL_LIST -O /tmp/flickr.html &> /dev/null
	RET=$?
	if [ $RET != 0 ] ; then
#		echo "~~~~~~~~~~~~~~~~~~~~~~~~~"
#		echo "ret=$RET"
		continue
	fi

	PIC_URL=`sed -nre 's/.*"([^"]*_m.jpg)".*/\1/p;' /tmp/flickr.html | sed -nre "${PIC}p"`

	PIC_DETAIL=`sed -nre 's/.*<a href="([^"]*)".*_m.jpg.*/\1/p;' /tmp/flickr.html | sed -nre "${PIC}p"`
#	echo $PIC_DETAIL

	PIC_URL_LARGE=`echo $PIC_URL | sed -nre "s/_m\.jpg/_o.jpg/p"`
	PIC_URL_THUMB=`echo $PIC_URL | sed -nre "s/_m\.jpg/_m.jpg/p"`

#	echo $PIC_URL_LARGE

	wget -q --limit-rate=1k $PIC_URL_LARGE -O /tmp/flickr_tmp.jpg &> /dev/null
	#wget -q $PIC_URL_LARGE -O /tmp/flickr_tmp.jpg &> /dev/null
	#wget -q $PIC_URL -O /tmp/flickr_tmp.jpg
	RET=$?
	if [ $RET != 0 ] ; then
#		echo "*************************"
#		echo "ret=$RET"
		continue
	fi

	md5sum -c ./flickr_invalid.md5 &> /dev/null
	RET=$?
	if [ $RET != 1 ] ; then
#		echo "........................."
#		echo "retry (photo currently not available)"
		continue
	fi

	jpeginfo=(`./jpegsize /tmp/flickr_tmp.jpg`)
	RET=$?
	if [ $RET != 0 ] ; then
#		echo "!!!!!!!!!!!!!!!!!!!!!!!!!"
#		echo "ret=$RET"
		continue
	fi

	x=${jpeginfo[0]}
	y=${jpeginfo[1]}
	mp=${jpeginfo[2]}

#	echo "$x _ $y _ $mp :)"

	FACTOR_X=$(( $x / $SCREEN_X ))
	FACTOR_Y=$(( $y / $SCREEN_Y ))
	FACTOR=1
#	echo -n "${FACTOR_X}_${FACTOR_Y} "
	if [ $FACTOR_X -lt $FACTOR_Y ] ; then
		FACTOR=$FACTOR_X
#		echo -n "X:"
	else
		FACTOR=$FACTOR_Y
#		echo -n "Y:"
	fi
#	echo $FACTOR

	case "$FACTOR" in
		[23])
#			echo "scaling down by 2 ($FACTOR)"
			SCALE=1/2
			djpeg -scale $SCALE -maxmemory 1024 -outfile /tmp/flickr.jpg /tmp/flickr_tmp.jpg 
			;;
		[4567])
#			echo "scaling down by 4 ($FACTOR)"
			SCALE=1/4
			djpeg -scale $SCALE -maxmemory 1024 -outfile /tmp/flickr.jpg /tmp/flickr_tmp.jpg 
			;;
		[89])
#			echo "scaling down by 8 ($FACTOR)"
			SCALE=1/8
			djpeg -scale $SCALE -maxmemory 1024 -outfile /tmp/flickr.jpg /tmp/flickr_tmp.jpg 
			;;
		#FIXME 10, 11, 12
		*)
#			echo "NOT scaling by $FACTOR"
			mv /tmp/flickr_tmp.jpg /tmp/flickr.jpg
			;;
	esac

	for i in `seq  $HIST -1 1` ; do
		h_list[$i]=${h_list[$(( $i - 1 ))]}
		h_thumb[$i]=${h_thumb[$(( $i - 1 ))]}
		h_large[$i]=${h_large[$(( $i - 1 ))]}
		h_scale[$i]=${h_scale[$(( $i - 1 ))]}
		h_detail[$i]=${h_detail[$(( $i - 1 ))]}
	done

	h_list[0]=$PIC_URL_LIST
	h_thumb[0]=$PIC_URL_THUMB
	h_large[0]=$PIC_URL_LARGE
	h_scale[0]="$x*$y, $mp MP"
	h_detail[0]=$PIC_DETAIL

	DONE=1

done


# generate html output

echo $H_HEAD > tickr_tmp.html

for i in `seq  0 $HIST` ; do
	echo "<tr>" >> tickr_tmp.html
	echo "	<td>" >> tickr_tmp.html
	echo "	<a href=\"${h_large[$i]}\"><img src=\"${h_thumb[$i]}\" border=\"0\" alt=\"pic$i\"></a>" >> tickr_tmp.html
	echo "	</td><td>" >> tickr_tmp.html
	echo "	&nbsp;&nbsp;&nbsp;<a href=\"${h_large[$i]}\">this pic in large</a> <font size=\"-2\">${h_scale[$i]}</font><br>" >> tickr_tmp.html
	echo "	&nbsp;&nbsp;&nbsp;<a href=\"${h_list[$i]}\">was found in this list of 10</a><br>" >> tickr_tmp.html
	echo "	&nbsp;&nbsp;&nbsp;<a href=\"http://flickr.com${h_detail[$i]}\">more details on this pic</a><br>" >> tickr_tmp.html
	echo "	</td>" >> tickr_tmp.html
	echo "</tr>" >> tickr_tmp.html
#	echo "${h_list[$i]}"
#	echo "${h_thumb[$i]}"
#	echo "${h_large[$i]}"
done

echo $H_FOOT >> tickr_tmp.html

#mv tickr_tmp.html /home/mazzoo/htdocs/tickr/tickr.html
mv tickr_tmp.html tickr.html

#killall fbskate
#/bin/fbskate /tmp/flickr.jpg &

#killall ee
#/usr/bin/ee /tmp/flickr.jpg &

#killall feh
#/usr/bin/feh --full-screen --auto-zoom --borderless --hide-pointer /tmp/flickr.jpg &
#/usr/bin/feh                                                       /tmp/flickr.jpg &

done
