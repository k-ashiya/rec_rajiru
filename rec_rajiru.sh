#!/bin/bash
function usage() {
  echo "Usage: rec_rajiru channel [branch] filename duration"
  echo "  channel=('R1'|'R2'|'FM')"
  echo "  branch=('AK'|'BK'|'CK'|'HK'); 'AK' by default."
  exit 1
}

if [ "$#" -ge 3 ]; then
  if [ "$1" != "R1" ] && [ "$1" != "R2" ] && [ "$1" != "FM" ]; then
    usage
  fi
  if [ "$1" = "R2" ]; then
      m3u8URL="https://nhkradioakr2-i.akamaihd.net/hls/live/511929/1-r2/1-r2-01.m3u8"
  fi
  if [ "$#" = 4 ] && ([ "$1" != "R1" ] || [ "$1" != "FM" ]); then
    if [ "$2" = "AK" ]; then
      if [ "$1" = "R1" ]; then
        m3u8URL="https://nhkradioakr1-i.akamaihd.net/hls/live/511633/1-r1/1-r1-01.m3u8"
      elif [ "$1" = "FM" ]; then
        m3u8URL="https://nhkradioakfm-i.akamaihd.net/hls/live/512290/1-fm/1-fm-01.m3u8"
      fi
      ch="$1"
    elif [ "$2" = "BK" ]; then
      if [ "$1" = "R1" ]; then
        m3u8URL="https://nhkradiobkr1-i.akamaihd.net/hls/live/512291/1-r1/1-r1-01.m3u8"
      elif [ "$1" = "FM" ]; then
        m3u8URL="https://nhkradiobkfm-i.akamaihd.net/hls/live/512070/1-fm/1-fm-01.m3u8"
      fi
      ch="$2$1"
    elif [ "$2" = "CK" ]; then
      if [ "$1" = "R1" ]; then
        m3u8URL="https://nhkradiockr1-i.akamaihd.net/hls/live/512072/1-r1/1-r1-01.m3u8"
      elif [ "$1" = "FM" ]; then
        m3u8URL="https://nhkradiockfm-i.akamaihd.net/hls/live/512074/1-fm/1-fm-01.m3u8"
      fi
      ch="$2$1"
    elif [ "$2" = "HK" ]; then
      if [ "$1" = "R1" ]; then
        m3u8URL="https://nhkradiohkr1-i.akamaihd.net/hls/live/512075/1-r1/1-r1-01.m3u8"
      elif [ "$1" = "FM" ]; then
        m3u8URL="https://nhkradiohkfm-i.akamaihd.net/hls/live/512076/1-fm/1-fm-01.m3u8"
      fi
      ch="$2$1"
    fi
    file="$3"
    dur="$4"
  elif [ "$#" = 4 ]; then
    usage
  else
    ch="$1"
    if [ "$1" = "R1" ]; then
      m3u8URL="https://nhkradioakr1-i.akamaihd.net/hls/live/511633/1-r1/1-r1-01.m3u8"
    elif [ "$1" = "R2" ]; then
      m3u8URL="https://nhkradioakr2-i.akamaihd.net/hls/live/511929/1-r2/1-r2-01.m3u8"
    elif [ "$1" = "FM" ]; then
      m3u8URL="https://nhkradioakfm-i.akamaihd.net/hls/live/512290/1-fm/1-fm-01.m3u8"
    else
      usage
    fi
    file="$2"
    dur="$3"
  fi
  date
  if [ -f rajiru.m3u8 ]; then
    rm rajiru.m3u8
  fi
  wget -O rajiru.m3u8 ${m3u8URL}
  num=`head -n6 rajiru.m3u8 | tail -n1`; first=`basename ${num} ".ts"`
  end=$(( first + (dur / 10) - 1 ))
  if [ $(( dur % 10 )) -ne 0 ]; then
    end=$(( end + 1 ))
  fi
  TMPDIR=rajiru_"$1"_`date +%m%d`
  mkdir -p "${TMPDIR}"
  cd "${TMPDIR}"
  DIR=`dirname ${num}`
  [[ ${DIR} =~ ^([-0-9Tfm]+)-([0-9]+)-([0-9]+) ]]
    DIR=`dirname ${m3u8URL}`/${BASH_REMATCH[1]}-${BASH_REMATCH[2]}
    DIRTMP=${BASH_REMATCH[3]}
  for i in `seq ${first} ${end}`; do
    j=$(( i % 2000 ))
    DIR1=``$(printf "%02d" $(( DIRTMP + i / 2000 )))
    wget -O "$i.ts" "${DIR}-${DIR1}/$j.ts"
    while [ ! -s "$i.ts" ]; do
      sleep 3
      wget -O "$i.ts" "${DIR}-${DIR1}/$j.ts"
    done
    echo "file '${i}.ts'" >> concat.txt;
    sleep 9
  done
  ffmpeg -f concat -safe 0 -i concat.txt -c copy "${file}"
  if [ -f "${file}" ]; then
    for i in `seq ${first} ${end}`; do
      rm "$i".ts
    done
  else
    exit 1
  fi
  mv "${file}" ../.
  cd ../
  rm -r "${TMPDIR}"
else
  usage
fi
