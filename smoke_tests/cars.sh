curl -X PUT \
    -H "content-type: application/json" \
    -d '[
        {"id": 1, "seats": 4},
        {"id": 2, "seats": 4},
        {"id": 3, "seats": 5}
    ]' \
    "http://localhost:8080/cars"