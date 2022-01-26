#!/bin/bash

#Install packages:

#cant install all these without root


if [[ $EUID -ne 0 ]]
  then

  echo 'Run as root!'
  echo 'Executing (sudo su)' && sudo su

fi

domain="exampledomain.com"

apt update

#print echo
ecco () {
  i=0
  while [ $i -lt $1 ]
    do
    echo
    ((i++))
  done
}

#check if package is installed
#Some ppa may not work

#check_pack () {
#
#  if [[ "$?" != "0" ]]
#    then
#    ecco 2
#    echo "Couldn't install $1"
#    ecco 1
#    sleep 1
#    echo 'Trying to add PPA...'
#    ecco 1
#
#    if [[ "$1" == "curl" ]]
#      then
#      
#      apt install add-apt-repository -y
#
#      if [[ "$?" != "0" ]]
#         then
#         ecco 1
#         apt install -y software-properties-common
#         
#         if [[ "$?" != "0" ]]
#            then
#            ecco 2
#            echo 'Cant install packages (ABORT)'
#            exit
#         fi
#         
#         apt install -y add-apt-repository && ecco 2
#      
#      fi
#
#      apt update -y
#      add-apt-repository -y ppa:kelleyk/curl
#    
#    fi
#
#    if [[ "$1" == "nginx" ]]
#      then
#      add-apt-repository ppa:nginx/stable
#    fi
#
#    if [[ "$1" == "php" ]]
#      then
#      add-apt-repository -y ppa:sergey-dryabzhinsky/php80
#    fi
#
#
#    if [[ "$1" == "python3" ]]
#      then
#      add-apt-repository -y ppa:deadsnakes/ppa  
#    fi
#    
#    apt update -y
#    apt install $1 -y 
# 
#  fi
#
#}

apt update
apt install -y curl
apt install -y wget nginx 
apt install -y php
apt install -y python3
apt install -y gcc
apt install -y php-fpm php-cli php-mysql php-curl php-json -y

ecco 3 && echo $(ufw app list) && ecco 3

  
ufw allow "Nginx Full"
ecco 2
echo -n "UFW FIREWALL" $(ufw status)


ecco 2
#disable apache2
systemctl disable apache2
systemctl stop apache2

#basic
systemctl stop nginx
systemctl start nginx
systemctl restart nginx
systemctl reload nginx
systemctl status nginx -l --no-pager 
systemctl enable nginx

ecco 3

touch host.list
echo $(hostname -I) >> host.list
echo "Saved hostname: $(hostname -I)..."

ecco 2
ecco 1
  
apt install -y certbot
apt install -y python3-certbot-nginx 
  
  if [[ "$?" != "0" ]]
    then
    ecco 2
    echo "Can't install certbot... (Configure PPA manually)"
    ?=127
    exit
  fi
  
echo """
server {
        listen 80 ;
        listen [::]:80 ;
        root /var/www/mail;
        index index.html index.htm index.nginx-debian.hmtl;
        server_name $domain www.$domain mail.$domain www.mail.$domain ;
        location / { 
                try_files $uri $uri/ =404;
        }
        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/run/php/php7.4-fpm.sock;
        }
}
    """ >> /etc/nginx/sites-available/mail
   
    # creating symlink
ln -s /etc/nginx/sites-available/mail /etc/nginx/sites-enabled/

ecco 2
systemctl reload nginx
echo -n 'Nginx Config Test... '
nginx -t
systemctl reload nginx
ecco 3

certbot --nginx --register-unsafely-without-email --non-interactive --agree-tos -d mail.$domain -d www.mail.$domain

ecco 3
echo 'Finished!'
ecco 2
exit
