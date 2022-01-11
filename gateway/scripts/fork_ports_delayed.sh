#!/bin/sh

echo "Forking IB Gateway port onto 0.0.0.0:5000\n"
while true; do
  ./proxy -config proxy.yaml
  sleep 5
done

