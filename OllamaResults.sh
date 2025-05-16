#!/usr/bin/env bash
set -e
MODEL=phi3
PORT=11435
CONTAINER=ollama_${MODEL}_$RANDOM
CONCURRENCY_LIST="1 4 8"

# ---------- 1. launch ----------
docker run -d --name ollama_$MODEL -p $PORT:11434 ollama/ollama
sleep 12                           # daemon init

# ---------- 2. pull model ----------
docker exec ollama_$MODEL ollama pull $MODEL

# ---------- 3. warm-up ----------
curl -s -o /dev/null -d '{"model":"'$MODEL'","prompt":"Hello"}' http://localhost:$PORT/api/generate

# ---------- 4. warm-path latency ----------
curl -s -o /dev/null -w "warm_ms,%{time_total}\n" \
     -d '{"model":"'$MODEL'","prompt":"Hello again"}' \
     http://localhost:$PORT/api/generate  | tee results.csv

# ---------- 5. cold-start latency ----------
docker stop  ollama_$MODEL
docker start ollama_$MODEL
sleep 5
curl -s -o /dev/null -w "cold_ms,%{time_total}\n" \
     -d '{"model":"'$MODEL'","prompt":"Hi"}' \
     http://localhost:$PORT/api/generate >> results.csv

# ---------- 6. throughput sweep ----------
for c in $CONCURRENCY_LIST; do
  hey -z 30s -c $c -m POST -T application/json \
      -d '{"model":"'$MODEL'","prompt":"Tell me a fun fact"}' \
      http://localhost:${PORT}/api/generate \
  | awk -v C=$c '
      /Requests\/sec/ { thr=$2 }
      /99th percentile/ { p95=$4 }
      END {
        printf "thr_c%s,%s\np95_c%s,%s\n", C, thr, C, p95
      }' >> results.csv
done


# ---------- 7. memory ----------
docker stats --no-stream --format "mem_mb,{{.MemUsage}}" >> results.csv

