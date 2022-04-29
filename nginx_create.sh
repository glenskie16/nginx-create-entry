#!/bin/bash

if [[ "$1" = "no"  || "$1" = "No" || "$1" = "NO" || "$1" = "nO" ]]; then
	echo "NO SSL"
##### EMPTY FILE #####
> "/etc/nginx/sites-enabled/$2.conf"

##### Fill FILE ######
cat <<EOT >> "/etc/nginx/sites-enabled/$2.conf"
server {
  
	listen 80;
	server_name $2 www.$2;
	
	root /var/www/$2;
	index index.html index.php;

}
EOT

##### RESTART NGINX #####
sudo systemctl restart nginx.service

##### SSL CREATION #####
sudo certbot certonly --webroot -w /var/www/$2/ -d $2

else
	echo "YES SSL"
##### EMPTY FILE #####
> "/etc/nginx/sites-enabled/$2.conf"

##### FILL FILE #####
cat <<EOT >> "/etc/nginx/sites-enabled/$2.conf"
server {
  
	listen 80;
	server_name $2 www.$2;
	return 301 https://$2\$request_uri;
}
server {
	
	listen 443 ssl http2;
	server_name $2;
	
	ssl_certificate /etc/letsencrypt/live/$2/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/$2/privkey.pem;

	root /var/www/$2;
	index index.html index.php;
	
	location = /favicon.ico {
		log_not_found off;
		access_log off;
	}

	location = /robots.txt {
		allow all;
		log_not_found off;
		access_log off;
	}
  
	location / {
		try_files \$uri \$uri/ /index.php?\$args;
	}
  
	location ~ \.php\$ {
		fastcgi_split_path_info ^(.+\.php)(/.+)\$;
		fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
		fastcgi_index index.php;
		include fastcgi_params;
		fastcgi_pass unix:/run/php/php7.4-fpm.sock;
	}

	location ~ ^/(torastatus)\$ {
		allow 127.0.0.1;
		fastcgi_split_path_info ^(.+\.php)(/.+)\$;
		fastcgi_pass unix:/run/php/php7.4-fpm.sock;
		fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
		fastcgi_index index.php;
		include fastcgi_params;
	}  
}
EOT

##### RESTART NGINX #####
sudo systemctl restart nginx.service
fi
