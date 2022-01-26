# auto-mailserver
Automates lots of installs and configs with a variety of parameters for installing a mail server.

# Multi Host Handling
Uses parallel-ssh to handle mutliple hosts at a time. Besides running the necessary code, it's easy to run basic commands for all hosts.

# Dovecot spamassasin opendkim postfix dmarc spf etc.
Uses Luke Smith's emailwiz.sh to install and configure all requirements simultaneously for each host.

# Nginx
Simply installs nginx with php support

# Certbot
Simply installs certificate issued by Let's Encrypt

# Data Management
No need for column names inside the csv file.
You can run commands for inspecting inputted data such as: 
--data-check
--data
--check

# --help
Prints manual


# Start
clone repository
chmod +x handle.sh
requirements: parallel-ssh sshpass openssl ssh ssh-copy-id
./handle.sh --help 
