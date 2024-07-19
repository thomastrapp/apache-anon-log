# Anonymous Logging for Apache

I use these log formats for some static websites. They do not log anything about the client, only the time and resource location of the request.

Basically:

```conf
ErrorLogFormat "[%t] [%l] [pid %P] %F: %E: [client 127.0.0.66:80] %M"
ErrorLog ${APACHE_LOG_DIR}/anon.error.log

LogFormat "127.0.0.66 %l %u %t \"%r\" %>s %b \"referer\" \"user-agent\"" anon
CustomLog ${APACHE_LOG_DIR}/anon.access.log anon
```

