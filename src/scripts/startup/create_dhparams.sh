#!/bin/bash

# This method may take an extremely long time to complete, be patient.
# It should be possible to use the same dhparam file for all sites, just
# specify the same file path under the "ssl_dhparam" parameter in the Nginx
# server config.
# The created file should be stored somewhere under /etc/letsencrypt/dhparams/
# to ensure persistence between restarts.
create_dhparam() {
    if [ -z "$DHPARAM_SIZE" ]; then
        echo "DHPARAM_SIZE unset, using default of 2048 bits"
        DHPARAM_SIZE=2048
    fi

    echo "
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                        ATTENTION!                       %
    %                                                         %
    % This script will now create a $DHPARAM_SIZE bit Diffie-Hellman   %
    % parameter to use during the SSL handshake.              %
    %                                                         %
    % >>>>>      This MIGHT take a VERY long time!      <<<<< %
    %    (Took 65 minutes for 4096 bit on an old 3GHz CPU)    %
    %                                                         %
    % However, there is some randomness involved so it might  %
    % be both faster or slower for you. 2048 is secure enough %
    % for today and quite fast to generate. These files will  %
    % only have to be created once so please be patient.      %
    % A message will be displayed when this process finishes. %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    "
    echo "Output file > $1"
    openssl dhparam -out $1 $DHPARAM_SIZE
    echo "
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % >>>>>   Diffie-Hellman parameter creation done!   <<<<< %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    "
}

# Return all unique "dhparam" file paths.
parse_dhparams() {
    sed -n -r -e 's&^\s*ssl_dhparam\s+(.*);.*&\1&p' "$1" | xargs -n1 echo | uniq
}

# Find any mentions of Diffie-Hellman parameters and create them if missing.
files_created=0
for conf_file in /etc/nginx/conf.d/*.conf*; do
    for dh_file in $(parse_dhparams $conf_file); do
        if [ ! -f $dh_file ]; then
            echo "Couldn't find the dhparam file $dh_file; creating it..."
            create_dhparam $dh_file
            chmod 600 $dh_file
            files_created=$((files_created+1))
        fi
    done
done

if [ "$files_created" -eq "0" ]; then
    echo "There was no need to create any dhparam files"
fi
