function kill_process {
    query=$1
    pid=`ps -aef | grep $query | grep -v sh| grep -v grep | awk '{print $2}'`

    if [ -z "$pid" ];
    then
        echo "no \${query} process running"
    else
        kill -9 $pid
    fi
}

station_information="station-information"
station_status="station-status"
station_san_francisco="station-san-francisco"
station_france="station-france"

echo "====Kill running producers===="

kill_process ${station_information}
kill_process ${station_status}
kill_process ${station_san_francisco}
kill_process ${station_france}
