docker run --name=ying-http-ssl-php -i -t -d -p 443:443 \
  -v /mnt/isilon/fondren-dss/dspace-test/test_assetstore:/var/www/html/assetstore \
  -v /mnt/isilon/fondren-dss/dspace-test/streaming:/var/www/html/streaming ying-http
docker network connect d6_dspacenet  ying-http-ssl-php
