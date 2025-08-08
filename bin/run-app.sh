#!/bin/bash

docker run -p80:80 -d -v $(pwd)/data:/app/data project/call-service-dashboard-app
