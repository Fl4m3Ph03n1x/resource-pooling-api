id=${1}

curl -X POST \
    -H "content-type: application/x-www-form-urlencoded" \
    -d "ID=$id" \
    "http://localhost:8080/dropoff"
