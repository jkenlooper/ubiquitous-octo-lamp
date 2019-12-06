#!/usr/bin/env bash

set -eu -o pipefail

ENVIRONMENT=$1
SRVDIR=$2
NGINXLOGDIR=$3
PORTREGISTRY=$4
INTERNALIP=$5
CACHEDIR=$6

# shellcheck source=/dev/null
source "$PORTREGISTRY"

# shellcheck source=/dev/null
source .env

cat <<HERE

limit_conn_zone \$binary_remote_addr zone=addr:1m;
limit_req_zone \$binary_remote_addr zone=piece_move_limit_per_ip:1m rate=60r/m;
limit_req_zone \$binary_remote_addr zone=piece_token_limit_per_ip:1m rate=60r/m;
limit_req_zone \$binary_remote_addr zone=puzzle_upload_limit_per_ip:1m rate=3r/m;
limit_req_zone \$server_name zone=puzzle_upload_limit_per_server:1m rate=20r/m;
limit_req_zone \$binary_remote_addr zone=puzzle_list_limit_per_ip:1m rate=30r/m;
limit_req_zone \$server_name zone=puzzle_list_limit_per_server:1m rate=20r/s;
limit_req_zone \$binary_remote_addr zone=player_email_register_limit_per_ip:1m rate=1r/m;

limit_req_zone \$binary_remote_addr zone=chill_puzzle_limit_per_ip:1m rate=30r/m;
# 10 requests a second = 100ms
limit_req_zone \$binary_remote_addr zone=chill_site_internal_limit:1m rate=10r/s;


server {
  # Redirect for old hosts
  listen       80;
  server_name puzzle.weboftomorrow.com www.puzzle.massive.xyz;
  return       301 http://puzzle.massive.xyz\$request_uri;
}

map \$request_uri \$loggable {
    # Don't log requests to the anonymous login link.
    ~/puzzle-api/bit/.* 0;
    ~/newapi/user-login/.* 0;

    default 1;
}

map \$request_uri \$hotlinking_policy {
  # Set routes to 0 to allow hotlinking or direct loading (bookmarked).

  # anonymous login links
  ~/puzzle-api/bit/.* 0;
  ~/newapi/user-login/.* 0;

  # Pages on the site.
  ~/chill/site/.* 0;

  # og:image image that can be used when sharing links
  /puzzle-massive-logo-600.png 0;
  /favicon.ico 0;
  ~/resources/.*/preview_full.jpg 0;

  default \$invalid_referer;
}

# Cache server
proxy_cache_path ${CACHEDIR} keys_zone=pm_cache_zone:10m inactive=600m;
server {
  listen      80;
  root ${SRVDIR}root;
  valid_referers server_names;

  # Rewrite the homepage url
  rewrite ^/index.html\$ / permanent;

  # redirect the old puzzlepage url
  rewrite ^/puzzle/(.*)\$ /chill/site/puzzle/\$1/ permanent;

  # rewrite old bit login (Will probably always need to have this rewritten)
  rewrite ^/puzzle-api/bit/([^/]+)/?\$ /newapi/user-login/\$1/;

  # handle old style of scale query param where 'scale=' meant to use without scaling
  rewrite ^/chill/site/puzzle/([^/]+)/\$ /chill/site/puzzle/\$1/scale/\$arg_scale/?;
  rewrite ^/chill/site/puzzle/([^/]+)/scale//\$ /chill/site/puzzle/\$1/scale/0/? last;
  rewrite ^/chill/site/puzzle/([^/]+)/scale/(\d+)/\$ /chill/site/puzzle/\$1/scale/1/? last;

  # redirect old puzzle queues
  rewrite ^/chill/site/queue/(.*)\$ /chill/site/puzzle-list/ permanent;


  location / {
    rewrite ^/\$ /chill/site/front/ last;

    #if (\$hotlinking_policy) {
    #  return 444;
    #}

    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$remote_addr;
    proxy_set_header X-Forwarded-Host \$remote_addr;
    proxy_cache pm_cache_zone;
    add_header X-Proxy-Cache \$upstream_cache_status;
    include proxy_params;
    proxy_pass http://localhost:${PORTORIGIN};
  }

  location /chill/site/ {
    # At this time all routes on chill/* are GETs
    limit_except GET {
      deny all;
    }

    # Redirect players without a user or shareduser cookie to the new-player page
    if (\$http_cookie !~* "(user|shareduser)=([^;]+)(?:;|\$)") {
      rewrite ^/chill/(.*)\$  /chill/site/new-player/?next=/chill/\$1? redirect;
    }

    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$remote_addr;
    proxy_set_header X-Forwarded-Host \$remote_addr;
    proxy_cache pm_cache_zone;
    add_header X-Proxy-Cache \$upstream_cache_status;
    include proxy_params;
    proxy_pass http://localhost:${PORTORIGIN};
  }

  location /chill/site/new-player/ {
    # Redirect players with a user cookie to the player profile page
    if (\$http_cookie ~* "user=([^;]+)(?:;|\$)") {
      rewrite ^/chill/(.*)\$  /chill/site/player/ redirect;
    }

    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$remote_addr;
    proxy_set_header X-Forwarded-Host \$remote_addr;
    proxy_cache pm_cache_zone;
    add_header X-Proxy-Cache \$upstream_cache_status;
    include proxy_params;
    proxy_pass http://localhost:${PORTORIGIN};
  }

  location /divulge/ {
    proxy_pass_header Server;
    proxy_set_header X-Real-IP  \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_pass http://localhost:${PORTDIVULGER};

    # Upgrade to support websockets
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";

    # Default timeout is 60s
    proxy_read_timeout 500s;
  }

HERE

if test "${ENVIRONMENT}" == 'development'; then

cat <<HEREBEDEVELOPMENT
  # certs for localhost only
  #ssl_certificate /etc/nginx/ssl/server.crt;
  #ssl_certificate_key /etc/nginx/ssl/server.key;

  # Only when in development should the site be accessible via internal ip.
  # This makes it easier to test with other devices that may not be able to
  # update a /etc/hosts file.
  server_name local-puzzle-massive $INTERNALIP;
HEREBEDEVELOPMENT

else

if test -e .has-certs; then
cat <<HEREENABLESSLCERTS
  # certs created from certbot
  #ssl_certificate /etc/letsencrypt/live/puzzle.massive.xyz/fullchain.pem;
  #ssl_certificate_key /etc/letsencrypt/live/puzzle.massive.xyz/privkey.pem;
HEREENABLESSLCERTS
else
cat <<HERETODOSSLCERTS
  # certs can be created from running 'bin/provision-certbot.sh ${SRVDIR}'
  # TODO: uncomment after they exist
  #ssl_certificate /etc/letsencrypt/live/puzzle.massive.xyz/fullchain.pem;
  #ssl_certificate_key /etc/letsencrypt/live/puzzle.massive.xyz/privkey.pem;
HERETODOSSLCERTS
fi

cat <<HEREBEPRODUCTION

  server_name puzzle-blue puzzle-green ${DOMAIN_NAME};

  location /.well-known/ {
    try_files \$uri =404;
  }
HEREBEPRODUCTION
fi

cat <<HERE
}

# Origin server
server {
  server_name localhost;
  listen      ${PORTORIGIN};
  #listen 443 ssl http2;

  ## SSL Params
  # from https://cipherli.st/
  # and https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html

  #ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  #ssl_prefer_server_ciphers on;
  #ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
  #ssl_ecdh_curve secp384r1;
  #ssl_session_cache shared:SSL:10m;
  #ssl_session_tickets off;
  #ssl_stapling on;
  #ssl_stapling_verify on;
  #resolver 8.8.8.8 8.8.4.4 valid=300s;
  #resolver_timeout 5s;
  ## Disable preloading HSTS for now.  You can use the commented out header line that includes
  ## the "preload" directive if you understand the implications.
  ##add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";
  #add_header Strict-Transport-Security "max-age=63072000; includeSubdomains";

  add_header X-Frame-Options DENY;
  add_header X-Content-Type-Options nosniff;

  set_real_ip_from localhost;
  real_ip_header X-Real-IP;
  real_ip_recursive on;

HERE
if (test -f web/dhparam.pem); then
cat <<HERE
  #ssl_dhparam /etc/nginx/ssl/dhparam.pem;
HERE
fi
cat <<HERE

  root ${SRVDIR}root;

  access_log  ${NGINXLOGDIR}access.log combined if=\$loggable;
  error_log   ${NGINXLOGDIR}error.log;

  # Limit the max simultaneous connections per ip address (10 per browser * 4 if within LAN)
  limit_conn   addr 40;

  client_max_body_size  20m;
  keepalive_disable  none;

  # Serve any static files at ${SRVDIR}root/*
  location / {
    try_files \$uri \$uri =404;
  }


  location /stats/ {
    root   ${SRVDIR}stats;
    index  awstats.puzzle.massive.xyz.html;
    auth_basic            "Restricted";
    auth_basic_user_file  ${SRVDIR}.htpasswd;
    access_log ${NGINXLOGDIR}access.awstats.log;
    error_log ${NGINXLOGDIR}error.awstats.log;
    rewrite ^/stats/(.*)\$  /\$1 break;
  }

  location /newapi/ {
    proxy_pass_header Server;
    proxy_set_header  X-Real-IP  \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_pass http://localhost:${PORTAPI};
    rewrite ^/newapi/(.*)\$ /\$1 break;
  }

  location /newapi/puzzle-upload/ {
    # Prevent too many uploads at once
    limit_req zone=puzzle_upload_limit_per_ip burst=5 nodelay;
    limit_req zone=puzzle_upload_limit_per_server burst=20 nodelay;

    proxy_pass_header Server;
    proxy_set_header  X-Real-IP  \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_pass http://localhost:${PORTAPI};
    rewrite ^/newapi/(.*)\$ /\$1 break;
  }

  location /newapi/player-email-register/ {
    # Prevent too many requests at once
    limit_req zone=player_email_register_limit_per_ip burst=5 nodelay;

    proxy_pass_header Server;
    proxy_set_header  X-Real-IP  \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_pass http://localhost:${PORTAPI};
    rewrite ^/newapi/(.*)\$ /\$1 break;
  }

  location /newapi/gallery-puzzle-list/ {
    expires 1m;
    add_header Cache-Control "public";

    proxy_pass_header Server;
    proxy_set_header  X-Real-IP  \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_pass http://localhost:${PORTAPI};
    rewrite ^/newapi/(.*)\$ /\$1 break;
  }

  location /newapi/puzzle-list/ {
    expires 1m;
    add_header Cache-Control "public";

    # Prevent too many puzzle list queries at once.
    limit_req zone=puzzle_list_limit_per_ip burst=20 nodelay;
    limit_req zone=puzzle_list_limit_per_server burst=200;
    limit_req_status 429;

    proxy_pass_header Server;
    proxy_set_header  X-Real-IP  \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_pass http://localhost:${PORTAPI};
    rewrite ^/newapi/(.*)\$ /\$1 break;
  }

  location /newapi/admin/ {
HERE
if test "${ENVIRONMENT}" != 'development'; then
cat <<HERE
    # Set to droplet ip not floating ip.
    # Requires using SOCKS proxy (ssh -D 8080 user@host)
    allow $INTERNALIP;
    allow 127.0.0.1;
    deny all;
HERE
fi
cat <<HERE
    auth_basic "Restricted Content";
    auth_basic_user_file ${SRVDIR}.htpasswd;

    proxy_pass_header Server;
    proxy_set_header  X-Real-IP  \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_pass http://localhost:${PORTAPI};
    rewrite ^/newapi/(.*)\$ /\$1 break;
  }

  location ~* ^/newapi/puzzle/.*/piece/.*/token/ {
    # TODO: not sure why keepalive_timeout was set to 0 before.
    #keepalive_timeout 0;
    limit_req zone=piece_token_limit_per_ip burst=60 nodelay;
    limit_req_status 429;

    proxy_pass_header Server;
    proxy_set_header  X-Real-IP  \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_pass http://localhost:${PORTAPI};
    rewrite ^/newapi/(.*)\$ /\$1 break;
  }

  location ~* ^/newapi/puzzle/.*/piece/.*/move/ {
    # Limit to max of 4 simultaneous puzzle piece moves per ip addr
    #limit_conn   addr 4;
    # Not exactly sure why, but setting it to 4 will not allow more then 3 players on a single IP.
    # This is set to 40 to allow at most 39 players on one IP
    limit_conn   addr 40;

    # TODO: not sure why keepalive_timeout was set to 0 before.
    #keepalive_timeout 0;
    limit_req zone=piece_move_limit_per_ip burst=60 nodelay;
    limit_req_status 429;

    proxy_pass_header Server;
    proxy_set_header  X-Real-IP  \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_pass http://localhost:${PORTAPI};
    rewrite ^/newapi/(.*)\$ /\$1 break;
  }

  #TODO: verify anonymous bit login works
  #location ~* ^/newapi/user-login/.*/ {
  #  # For just this url; don't restrict by referrers
  #  proxy_pass_header Server;
  #  proxy_set_header Host \$http_host;
  #  proxy_set_header  X-Real-IP  \$remote_addr;
  #  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  #  proxy_redirect off;
  #  proxy_pass http://localhost:${PORTAPI};

  #  rewrite ^/newapi/(.*)\$  /\$1 break;
  #}


  location ~* ^/chill/site/puzzle/.*\$ {

    # Allow loading up to 15 puzzles with each request being delayed by
    # 2 seconds.
    limit_req zone=chill_puzzle_limit_per_ip burst=15;

    proxy_pass_header Server;
    proxy_set_header  X-Real-IP  \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

    proxy_pass http://localhost:${PORTCHILL};

    # Redirect players without a user or shareduser cookie to the new-player page
    if (\$http_cookie ~* "(user|shareduser)=([^;]+)(?:;|\$)") {
      rewrite ^/chill/(.*)\$  /\$1 break;
    }
    rewrite ^/chill/(.*)\$  /chill/site/new-player/?next=/chill/\$1 redirect;
  }

  location /chill/site/internal/ {
    # Limit the response rate for the server as these requests can be called
    # multiple times on a page request.
    # Each request is delayed by 100ms up to 20 seconds.
    limit_req zone=chill_site_internal_limit burst=200;
    limit_req_status 429;

    proxy_pass_header Server;
    proxy_set_header  X-Real-IP  \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

    proxy_pass http://localhost:${PORTCHILL};

    expires 60m;
    add_header Cache-Control "public";
    rewrite ^/chill/(.*)\$  /\$1 break;
  }


  location /chill/ {
    proxy_pass_header Server;
    proxy_set_header  X-Real-IP  \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

    proxy_pass http://localhost:${PORTCHILL};
    rewrite ^/chill/(.*)\$  /\$1 break;
  }

  location /chill/site/ {
    proxy_pass_header Server;
    proxy_set_header  X-Real-IP  \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

    ## Prevent others from skipping cache
    #proxy_set_header Chill-Skip-Cache "";

    expires 1m;
    add_header Cache-Control "public";

    proxy_pass http://localhost:${PORTCHILL};

    rewrite ^/chill/(.*)\$  /\$1 break;
  }

  location /chill/site/new-player/ {
    proxy_pass_header Server;
    proxy_set_header  X-Real-IP  \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

    expires 10m;
    add_header Cache-Control "public";

    proxy_pass http://localhost:${PORTCHILL};

    rewrite ^/chill/(.*)\$  /\$1 break;
  }

  location /chill/site/admin/ {

HERE
if test "${ENVIRONMENT}" != 'development'; then
cat <<HERE
    # Set to droplet ip not floating ip.
    # Requires using SOCKS proxy (ssh -D 8080 user@host)
    allow $INTERNALIP;
    allow 127.0.0.1;
    deny all;
HERE
fi
cat <<HERE

    proxy_pass_header Server;
    proxy_set_header  X-Real-IP  \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

    proxy_pass http://localhost:${PORTCHILL};

    auth_basic "Restricted Content";
    auth_basic_user_file ${SRVDIR}.htpasswd;

    rewrite ^/chill/(.*)\$  /\$1 break;
  }

HERE
if test "${ENVIRONMENT}" != 'development'; then
cat <<HEREBEPRODUCTION
  location ~* ^/theme/.*?/(.*)\$ {
    expires 1y;
    add_header Cache-Control "public";
    alias ${SRVDIR}dist/\$1;
  }

  location /media/ {
    expires 1y;
    add_header Cache-Control "public";
    root ${SRVDIR};
  }
HEREBEPRODUCTION

else

cat <<HEREBEDEVELOPMENT
  location /theme/ {
    rewrite ^/theme/(.*)\$  /chill/theme/\$1;
  }

  location /media/ {
    expires 1y;
    add_header Cache-Control "public";
    rewrite ^/media/(.*)\$  /chill/media/\$1;
  }
HEREBEDEVELOPMENT
fi
cat <<HERE

  location /media/bit-icons/ {
    expires 1M;
    add_header Cache-Control "public";
    root ${SRVDIR};
  }

  location ~* ^/resources/.*/(scale-100/raster.png|scale-100/raster.css|pzz.css|pieces.png)\$ {
    expires 1M;
    add_header Cache-Control "public";
    root ${SRVDIR};
  }
  location ~* ^/resources/.*/(preview_full.jpg)\$ {
    expires 1M;
    add_header Cache-Control "public";
    root ${SRVDIR};
  }
  location ~* ^/resources/.*/(original.jpg)\$ {
    allow $INTERNALIP;
    allow 127.0.0.1;
    deny all;
    root ${SRVDIR};
  }

  error_page 500 501 502 504 505 506 507 /error_page.html;
  location = /error_page.html {
    internal;
  }

  error_page 503 /overload_page.html;
  location = /overload_page.html {
    internal;
  }

  error_page 401 403 /unauthorized_page.html;
  location = /unauthorized_page.html {
    internal;
  }

  error_page 404 /notfound_page.html;
  location = /notfound_page.html {
    internal;
  }

  error_page 429 /too_many_requests_page.html;
  location = /too_many_requests_page.html {
    internal;
  }

  error_page 409 /conflict_page.html;
  location = /conflict_page.html {
    internal;
  }
}
HERE
