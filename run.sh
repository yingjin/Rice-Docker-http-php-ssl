docker run --name=ying-http-ssl-php -i -t -d -p 443:443 \
  -v /mnt/isilon/fondren-dss/dspace-test/assetstore:/var/www/html/assetstore \
  -v /mnt/isilon/fondren-dss/dspace-test/streaming:/var/www/html/streaming \
  -v /mnt/isilon/fondren-dss/dspace-test/iiif/manifest:/var/www/html/manifest \
  -v /mnt/isilon/fondren-dss/dspace-test/ohms/cachefiles:/var/www/html/ohms/cachefiles ying-http
docker network connect d6_dspacenet  ying-http-ssl-php
