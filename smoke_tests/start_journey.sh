id=${1}
people=${2}

curl -X POST \
    -H "content-type: application/json" \
    -d "{\"id\": $id, \"people\": $people}" \
    "http://localhost:8080/journey"
