#!/usr/bin/env bash
# Lance un run Locust en journalisant pods / CPU toutes les 2 s.
# Usage : ./serving/run_with_log.sh <users> <spawn-rate> <run-time>   (ISVC_HOST exporté)
set -u
: "${ISVC_HOST:?ISVC_HOST non défini}"
U=$1; R=$2; T=$3
SEL="serving.kserve.io/inferenceservice=scoring-model"
OUT=reports/m5/scale_run_${U}.log
: > "$OUT"
START=$(date +%s)
(
  while true; do
    N=$(kubectl get pods -n scoring -l "$SEL" --no-headers 2>/dev/null | grep -c '2/2 *Running')
    CPU=$(kubectl top pods -n scoring -l "$SEL" --no-headers 2>/dev/null \
      | awk '{gsub("m","",$2); s+=$2; n++} END{if(n) printf "%.0f", s/n; else print 0}')
    echo "$(( $(date +%s) - START )) $N $CPU" >> "$OUT"
    sleep 2
  done
) &
LOGGER=$!
trap 'kill $LOGGER 2>/dev/null' EXIT

uv run locust -f serving/locustfile.py --host http://localhost:30080 \
  --users "$U" --spawn-rate "$R" --run-time "$T" --headless ${LOCUST_ARGS:-} \
  --csv=reports/m5/run_${U} --html=reports/m5/run_${U}.html

kill $LOGGER 2>/dev/null
echo
echo "=== Scale-up run_${U} ==="
awk '$2>m{m=$2;t=$1} {if($3>0){s+=$3;c++}} END{printf "Pods max: %d (atteint à %d s)\nCPU moyen par pod: %.0f m\n", m, t, c?s/c:0}' "$OUT"
