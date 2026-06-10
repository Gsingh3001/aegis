SCENARIOS = {
  "diversion": {
    "id": "INC-2024-001",
    "name": "The Diversion",
    "desc": "Loud port scan on HOST-A concealing DNS exfil on HOST-F",
    "telemetry": {
      "incident_id": "INC-2024-001",
      "alerts": [
        {"id":"ALERT-001","severity":"HIGH","type":"Network Scan",
         "source_host":"HOST-A","source_ip":"192.168.1.45",
         "port_scan_count":847,"time":"10:14-10:17 UTC","siem_score":92},
        {"id":"ALERT-002","severity":"LOW","type":"Unusual DNS",
         "source_host":"HOST-F","source_ip":"192.168.1.89",
         "destination":"203.0.113.7","query_rate":"2/min",
         "pattern":"base64 subdomains — DNS tunnel","time":"10:09 UTC ongoing","siem_score":31}
      ],
      "auth_logs": [
        {"account":"svc-prod-7","target":"HOST-F","time":"10:09 UTC",
         "note":"Normally only accesses HOST-B and HOST-C"}
      ],
      "hosts": {
        "HOST-A": {"role":"dev-workstation","data":"INTERNAL"},
        "HOST-F": {"role":"finance-reporting","data":"CONFIDENTIAL — Q4 earnings"}
      }
    }
  }
}
def get_scenario(name="diversion"):
    return SCENARIOS.get(name)
