#!/bin/bash
#
# Draw console plot charts for:
#       Daily http requests distribution per hour
#       Daily maximum requests per seconds grouped by hour
#
# Usage:
#       sudo apt install gnuplot
#       See SCRIPT_USAGE
#       If access log is gzipped (.gz), then use isLogCompressed = 1

readonly SCRIPT_USAGE="bash $0 <pathToNginxLogFile> <grepDate> <isLogCompressed:0|1>\n"\
"Sample: ./http-requests-daily-distribution.sh /var/log/nginx/access.log.1 30/Mar/2021 0"

pathToNginxLogFile="$1"
grepDate="$2"
isLogCompressed=$3

[[ ! $pathToNginxLogFile ]] && echo -e "Bad input: pathToNginxLogFile\nUsage: $SCRIPT_USAGE" && exit 1
[[ ! -e $pathToNginxLogFile ]] && echo -e "Bad input: pathToNginxLogFile: File not exists\nUsage: $SCRIPT_USAGE" && exit 1
[[ ! $grepDate ]] && echo -e "Bad input: grepDate\nUsage: $SCRIPT_USAGE" && exit 1
[[ ! $isLogCompressed ]] && echo -e "Bad input: isLogCompressed\nUsage: $SCRIPT_USAGE" && exit 1

logReader="cat"
(( $isLogCompressed )) && logReader="zcat"

nginxData="$logReader $pathToNginxLogFile | grep '^$grepDate:<H>'"

chartData1=""
chartData2=""
echo -n "Doing hour (00-24): "
for h in `printf "%02d " {0..24}`; do
    echo -n "$h "
    # Daily http requests distribution per hour: Total
    chartData1+=$(echo -n "$h "; eval ${nginxData/<H>/$h} | wc -l)
    chartData1+="\n"
    # Daily http requests distribution per hour: Max per second
    chartData2+=$(echo -n "$h "; eval ${nginxData/<H>/$h} | wc -l | awk '{ print int($1 / 3600) }')
    chartData2+="\n"
done
echo ""

gnuPlot=" \
set terminal dumb size 265 28; \
set xdata time; \
set timefmt '%H'; \
set format x '%H'; \
set offset 1, 1, 1, 1; \
set boxwidth 0; \
plot '-' using 1:2 with boxes; \
"

echo ""
echo "Daily http requests distribution per hour: Total"
echo -e $chartData1 | gnuplot -e "$gnuPlot"
echo "Daily http requests distribution per hour: Max per second"
echo -e $chartData2 | gnuplot -e "$gnuPlot"
