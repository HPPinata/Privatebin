#!/bin/bash
# docker-compose und curl müssen installiert sein

mkdir /var/privatebin
cd /var/privatebin

curl -o conf.php https://raw.githubusercontent.com/PrivateBin/PrivateBin/master/cfg/conf.sample.php
mkdir privatebin-data
chown -R nobody:nobody privatebin-data

cat <<'EOL' > ./Caddyfile
{
  email    mail@example.net
  key_type p384
  #acme_ca  https://acme-staging-v02.api.letsencrypt.org/directory
  local_certs
}

privatebin {
  reverse_proxy privatebin:8080
}
EOL

cat <<'EOL' > ./compose.yml
services:
# Caddy als reverse proxy für SSL/TLS
  caddy:
    image: caddy:alpine
    container_name: caddy
    networks:
      - intern
    ports:
      - 80:80
      - 443:443
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    restart: unless-stopped

  privatebin:
    image: privatebin/nginx-fpm-alpine
    container_name: privatebin
    read_only: true
    networks:
      - intern
    volumes:
      - ./privatebin-data:/srv/data:rw
      - ./conf.php:/srv/cfg/conf.php:ro
    environment:
      - TZ=Europe/Berlin
      - PHP_TZ=Europe/Berlin
    restart: unless-stopped

  mariadb:
    image: mariadb:latest
    container_name: mariadb
    networks:
      - intern
    volumes:
      - db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=Z3r0P4ss
      - MYSQL_PASSWORD=Z3r0P4ss
      - MYSQL_DATABASE=privatebin
      - MYSQL_USER=privatebin
      - MARIADB_AUTO_UPGRADE=true
      - MARIADB_DISABLE_UPGRADE_BACKUP=true
    restart: unless-stopped

volumes:
  caddy_data:
  caddy_config:
  db:

networks:
  intern:
EOL

cat <<'EOL' > /var/privatebin/update.bash
#!/bin/bash
cd /var/privatebin
docker-compose pull
docker-compose build --pull
docker-compose up -dV
docker system prune -a -f --volumes
EOL
chmod +x /var/privatebin/update.bash

cat <<'EOL' > /etc/systemd/system/privatebin.service
[Unit]
Description=Start Privatebin Container
After=network-online.target docker.service

[Service]
Type=oneshot
ExecStart=bash -c '/var/privatebin/update.bash'
ExecStop=bash -c '/bin/docker-compose down -f /var/privatebin/compose.yml'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOL
systemctl enable /etc/systemd/system/privatebin.service
