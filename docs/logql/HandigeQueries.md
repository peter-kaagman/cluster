 Geeft een lijst van article requests
 ```
 lq --since=720h --limit=5000 '
{job="fluent-bit",service_name="nginx-ingress"}
| json
| line_format "{{.message}}"
| json
| host="mysite.prjv.nl"
| uri=~"/article/.*"
| line_format "{{.remote_addr}}\t{{.status}}\t{{.uri}}\t{{.user_agent}}"
'
```

Geeft google bot bezoeken
```
lq --since=720h --limit=5000 '
{job="fluent-bit",service_name="nginx-ingress"}
| json
| line_format "{{.message}}"
| json
| host="mysite.prjv.nl"
| uri=~"/article/.*"
| user_agent=~"(?i).*google.*"
| line_format "{{.time}}\t{{.remote_addr}}\t{{.uri}}"
' | sort
```

met verified IP
```
lq --since=720h --limit=5000 '
{job="fluent-bit",service_name="nginx-ingress"}
| json
| line_format "{{.message}}"
| json
| host="mysite.prjv.nl"
| uri=~"/article/.*"
| remote_addr=~"66\\.249\\.75\\.(196|197)"
| line_format "{{.time}}\t{{.remote_addr}}\t{{.status}}\t{{.uri}}\t{{.user_agent}}"
'
```