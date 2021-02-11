#!/bin/bash
# Usage: $0 input output

function yes_or_no {
    while true; do
        read -p "$* [y/n]: " yn
        case $yn in
            [Yy]*) return 0  ;;  
            [Nn]*) echo "Aborted" ; return  1 ;;
        esac
    done
}

INPUT_FILE=$1
if ! [[ -f ${INPUT_FILE} ]]; then
    echo "Could not find input file ${INPUT_FILE}"
    echo "Usage: $0 input.mp4 [output.mp4]"
    exit 1
fi

OUTPUT_FILE="$(dirname "${INPUT_FILE}")/anon_$(basename "${INPUT_FILE}")"
if [[ $# > 1 ]]; then
    OUTPUT_FILE=$2
fi
if [[ -f ${OUTPUT_FILE} ]]; then
    yes_or_no "${OUTPUT_FILE} already exists. Do want to overwrite it?" || exit 0
fi

TMP_DIR="$(dirname ${INPUT_FILE})/$(basename ${INPUT_FILE})_temp"
COUNT=1
while [[ -d ${TMP_DIR} ]]; do
    TMP_DIR="$(dirname "${INPUT_FILE}")/$(basename "${INPUT_FILE}")_temp${COUNT}"
    COUNT=$((COUNT+1))
done

# Read parameters of original video.
FRAMERATE=$(ffprobe -loglevel error -select_streams v:0 -show_entries stream=r_frame_rate -of default=nk=1:nw=1 ${INPUT_FILE})
# Useful ideas from: https://stackoverflow.com/questions/34442156/ffmpeg-avconv-transcode-using-same-codec-and-params-as-input/34457444#34457444
# Alternatively you could just use ffprobe to get video stream bitrate,
# but not all inputs will show stream bitrate info, so ffmpeg is used instead.
#~ size="$(ffmpeg -i "${INPUT_FILE}" -f null -c copy -map 0:v:0 - |& awk -F'[:|kB]' '/video:/ {print $2}')"
#~ codec="$(ffprobe -loglevel error -select_streams v:0 -show_entries stream=codec_name -of default=nk=1:nw=1 "${INPUT_FILE}")"
#~ duration="$(ffprobe -loglevel error -select_streams v:0 -show_entries format=duration -of default=nk=1:nw=1 "${INPUT_FILE}")"
#~ bitrate="$(bc -l <<< "$size"/"$duration"*8.192)"

# Video2Image:
mkdir ${TMP_DIR}
ffmpeg -i "${INPUT_FILE}" -f image2 "${TMP_DIR}/%05d.png"

# Run anonymizer on images.
if [[ -f ./anonymizer.sif ]]; then
    singularity run --nv --bind "${TMP_DIR}":/tmp_dir anonymizer.sif --input /tmp_dir --image-output /tmp_dir --weights ./weights --no-write-detections --obfuscation-kernel 21,1,9
else
    python3 anonymizer/bin/anonymize.py --input "${TMP_DIR}" --image-output "${TMP_DIR}" --weights ./weights --no-write-detections --obfuscation-kernel 21,1,9
fi

# Image2Video using original audio
ffmpeg -r ${FRAMERATE} -i "${TMP_DIR}/%05d.png" -i "${INPUT_FILE}" -c:a copy -c:v libx264 -preset slow -pix_fmt yuv420p -map 0:v:0 -map 1:a:0 -y "${OUTPUT_FILE}"

rm -r "${TMP_DIR}"
