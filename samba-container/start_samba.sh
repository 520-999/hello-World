#!/bin/bash
docker run -d --restart=always --name mysamba  --privileged -p 139:139 -p 445:445 -v /samba/etc/samba:/etc/samba -v /samba/var/log/samba:/var/log/samba -v /home:/home samba:4.1 init
