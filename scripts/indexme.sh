curl -i -X POST "https://api.indexnow.org/indexnow" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d '{
    "host": "mysite.prjv.nl",
    "key": "1368adee-a218-4e26-b137-6659bb930b0a",
    "keyLocation": "https://mysite.prjv.nl/1368adee-a218-4e26-b137-6659bb930b0a.txt",
    "urlList": [
      "https://mysite.prjv.nl/article/from_distribution_lists_to_a_rule_evaluation_engine"
    ]
  }'