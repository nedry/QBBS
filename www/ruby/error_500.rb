r = Apache.request
r.content_type = "text/plain"
r.send_http_header
print "Ruby Error: ",r.prev.uri,"\n\n"
print r.prev.error_message
