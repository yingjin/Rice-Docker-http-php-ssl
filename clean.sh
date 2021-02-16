# instructions for how to export db and reuse it for next time deployment
#
#docker exec -it riceDspacedb /bin/bash
#pg_dump -U dspace -f /2020-07-22-dump-dev.sql dspace
#docker cp riceDspacedb:/2020-07-22-dump-dev.sql dspace/PSQL/
#cp 2020-07-22-dump-dev.sql dspace-dump.sql

docker stop ying-http-ssl-php
docker rm ying-http-ssl-php
docker rmi ying-http
