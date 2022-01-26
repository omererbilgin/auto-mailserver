#!/bin/bash


#data path | columns: pass, port, user@host, domain
datap="core.csv"
#host path
hostp=".hosts"
setup="setup.sh"

hostc=$(cat $hostp | wc -l)


#sends setup to hosts changing domain names dynamically found in data path
if [[ "$1" == "--script" ]]
then

    i=0
    while [[ $i -lt $hostc ]]
    do
        mkdir "host${i}"
        cp "$setup" "host${i}"

        i=$((i + 1))
    done

    j=0
    while IFS=, read -r pass port host domain
    do

        sed -i "16s@.*@domain=\"$domain\"@" host${j}/$setup
        j=$((j + 1))
    
    done < $datap

    x=0
    while IFS=, read -r vps
    do
        scp host${x}/setup.sh $vps:~/setup.sh &
        x=$((x + 1))
    done < $hostp
    exit

    while true
    do
        if ! pgrep -x "scp" > /dev/null
        then
            printf "\n\n\nDONE"
            exit
        fi

        echo 'Sending...'
    done
fi

if [[ "$1" == "--run" ]]
then
    parallel-ssh -t 0 -h $hostp -- chmod +x $setup
    parallel-ssh -t 0 -h $hostp -- $setup
fi

#quick update
if [[ "$1" == "-q" || "$1" == "--update" ]]
then
    parallel-ssh -t 0 -h $hostp -- apt update
fi

#data check
if [[ "$1" == "--prep-check" ]]
then
    
    while IFS=@ read -r usr ip
    do
        ping -c 1 $ip
    done < $hostp

    printf "\n\nTrying ssh:\n\n"
    parallel-ssh -i -h $hostp ls
    
    printf "\n\nChecking domains to setup:\n\n"

    parallel-ssh -i -h $hostp "sed -n 16p $setup"

    exit
fi


if [[ "$1" == "--ssl-check" ]]
then

    printf "\n\nChecking SSL:\n\n"

    sleep 2

    while IFS=, read -r pass port host doma
    do
        echo "$doma Certificate details:"
		echo|openssl s_client -servername $doma -connect $doma:443 2>/dev/null|openssl x509 -text |egrep "DNS:"|tr -d " \t"|tr , '\n'|sed  's/^/	/'
        echo|openssl s_client -servername $doma -connect $doma:443 2>/dev/null|openssl x509 -noout -issuer|sed 's/issuer=/Issuer: /'
        echo
        echo
        echo
    done < $datap
    exit
fi


# config mail and generate dkim/dmarc/spf records
if [[ "$1" == "--record-key" ]]
then
    parallel-ssh -i -h $hostp "rm ~/emailwiz.sh" 
    
    i=0
    
    while IFS=, read -r pass port host domain 
    do
        cp emailwiz.sh host${i}/emailwiz.sh
        sed -i "36s@.*@postintname=\"$domain\"@" host${i}/emailwiz.sh
        scp host${i}/emailwiz.sh $host:~/emailwiz.sh &
        i=$((i + 1))
    done < $datap

    while true
    do
        if ! pgrep -x "scp" > /dev/null
        then
            printf "\n\n\nDONE\n\n\n"
            break
        fi
        sleep 4
        echo 'Sending files...'
    done

    parallel-ssh -i -h $hostp "chmod +x ~/emailwiz.sh"
    parallel-ssh -t 0 -h $hostp "./emailwiz.sh"
    parallel-ssh -h $hostp "cp dns_emailwizard /var/www/html/txt"


    tmpR="$RANDOM${RANDOM}_dns_key"
    mkdir $tmpR
    while IFS=@ read -r host
    do
        wget $host/txt -O "$tmpR/${host}_key"
    done < $hostp

    printf "\n\nGot the keys in: $tmpR\n\n"
fi

#install keys
if [[ "$1" == "--ssh-key" ]]
then

    #ssh-keygen -t rsa
    printf "Modifying ssh-copy-id to disable strict host checking: \n\n"
    
    #only tested ubuntu 20.04
    #to modify ssh-copy-id to accept StrictHostKeyChecking just like in ssh
    sudo sed -i.bak 's/ssh \$/ssh -o StrictHostKeyChecking=no \$/' $(which ssh-copy-id)

    printf "\n\nRun ssh-keygen for new keys.\nThis may take a long time...\n\n"

    while IFS=, read -r pass port vps dum
    do
        echo $vps
        export SSHPASS=$pass
        sshpass -e ssh-copy-id -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no $vps || echo "FAILED" &
    done < $datap

    while true
    do
        if ! pgrep -x "ssh-copy-id" > /dev/null
        then
            printf "\n\n\n[ENTER]\n\n\n"
            read -n1 ans
            exit
        fi
        echo 'Sending keys'
        sleep 0.5
    done

fi

if [[ "$1" == "-c" || "$1" == "--command" ]]
then
    cmd="$2"
    if [[ "$2" == "" ]]
    then
        echo
        echo -n "Command: "
        read cmd
    fi

    parallel-ssh -h $hostp "$cmd"
    exit
fi

if [[ "$1" == "--data-check" ]]
then

    printf "\nPORT |   PASS  |   HOST               |   DOMAIN\n\n\n"
    while IFS=, read -r pass port host doma
    do

        if [[ $pass == "" ]]
        then
            pass="NO"
        else
            pass="YES"
        fi

        echo "$port   |   $pass   |   $host   |   $doma"
    done < $datap

fi

if [[ "$1" == "--show-output" ]]
then
    cmd="$2"
    if [[ "$2" == "" ]]
    then
        echo
        echo -n "Command: "
        read cmd
    fi

    parallel-ssh -i -h $hostp "$cmd"
    exit
fi

if [[ "$1" == '--data-format' ]]
then

    printf "\n\nDefault File Names: \n\n\n"
    printf "    .hosts       | Keeps host information\n"
    printf "    core.csv     | Keeps core information of hosts\n"
    printf "    setup.sh     | Keeps the script text for installing the webserver and ssl\n"
    printf "    emailwiz.sh  | Keeps the script text for generating TXT records\n"
    printf "\n\nFormat: \n\n\n"
    printf "    .hosts       | user@ip for each line\n"
    printf "    core.csv     | CSV columns: password , connection port , user@ip , domain\n\n"
fi

if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "" ]]
then
    printf "\n\nAvailable options: \n\n\n"
    printf "    --ssh-key     | Installs ssh keys to target host(s)\n"
    printf "    --record-key  | Generates necessary TXT host records\n"
    printf "    --ssl-check   | Gets ssl information for each host\n"
    printf "    -q, --update  | Updates servers using apt\n"
    printf "    --script      | Sends setup script to target host(s)\n"
    printf "    --prep-check  | Checks host status and information sent to host(s)\n"
    printf "    --run         | Runs the setup script on each host\n"
    printf "    --data-check  | Shows human readable data in files\n"
    printf "    -c, --command | Runs command for all hosts\n"
    printf "    --show-output | Runs command for all hosts but with output\n"
    printf "    --data-format | Prints a guide for inputting data\n"
    printf "    -h, --help    | Prints available options (this page)\n\n"
fi