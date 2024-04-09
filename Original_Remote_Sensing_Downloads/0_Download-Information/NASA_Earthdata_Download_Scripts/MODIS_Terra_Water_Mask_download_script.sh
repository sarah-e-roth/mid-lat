#!/bin/bash

GREP_OPTIONS=''

cookiejar=$(mktemp cookies.XXXXXXXXXX)
netrc=$(mktemp netrc.XXXXXXXXXX)
chmod 0600 "$cookiejar" "$netrc"
function finish {
  rm -rf "$cookiejar" "$netrc"
}

trap finish EXIT
WGETRC="$wgetrc"

prompt_credentials() {
    echo "Enter your Earthdata Login or other provider supplied credentials"
    read -p "Username (sarah.e.roth): " username
    username=${username:-sarah.e.roth}
    read -s -p "Password: " password
    echo "machine urs.earthdata.nasa.gov login $username password $password" >> $netrc
    echo
}

exit_with_error() {
    echo
    echo "Unable to Retrieve Data"
    echo
    echo $1
    echo
    echo "https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2015.01.01/MOD44W.A2015001.h11v05.006.2018033150737.hdf"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2015.01.01/MOD44W.A2015001.h11v05.006.2018033150737.hdf -w '\n%{http_code}' | tail  -1`
    if [ "$approved" -ne "200" ] && [ "$approved" -ne "301" ] && [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w '\n%{http_code}' https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2015.01.01/MOD44W.A2015001.h11v05.006.2018033150737.hdf | tail -1)
    if [[ "$status" -ne "200" && "$status" -ne "304" ]]; then
        # URS authentication is required. Now further check if the application/remote service is approved.
        detect_app_approval
    fi
}

setup_auth_wget() {
    # The safest way to auth via curl is netrc. Note: there's no checking or feedback
    # if login is unsuccessful
    touch ~/.netrc
    chmod 0600 ~/.netrc
    credentials=$(grep 'machine urs.earthdata.nasa.gov' ~/.netrc)
    if [ -z "$credentials" ]; then
        cat "$netrc" >> ~/.netrc
    fi
}

fetch_urls() {
  if command -v curl >/dev/null 2>&1; then
      setup_auth_curl
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        curl -f -b "$cookiejar" -c "$cookiejar" -L --netrc-file "$netrc" -g -o $stripped_query_params -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  elif command -v wget >/dev/null 2>&1; then
      # We can't use wget to poke provider server to get info whether or not URS was integrated without download at least one of the files.
      echo
      echo "WARNING: Can't find curl, use wget instead."
      echo "WARNING: Script may not correctly identify Earthdata Login integrations."
      echo
      setup_auth_wget
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        wget --load-cookies "$cookiejar" --save-cookies "$cookiejar" --output-document $stripped_query_params --keep-session-cookies -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  else
      exit_with_error "Error: Could not find a command-line downloader.  Please install curl or wget"
  fi
}

fetch_urls <<'EDSCEOF'
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2015.01.01/MOD44W.A2015001.h11v05.006.2018033150737.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2015.01.01/MOD44W.A2015001.h12v05.006.2018033151433.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2014.01.01/MOD44W.A2014001.h12v05.006.2018033151433.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2014.01.01/MOD44W.A2014001.h11v05.006.2018033150735.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2013.01.01/MOD44W.A2013001.h11v05.006.2018033150734.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2013.01.01/MOD44W.A2013001.h12v05.006.2018033151431.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2012.01.01/MOD44W.A2012001.h12v05.006.2018033151430.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2012.01.01/MOD44W.A2012001.h11v05.006.2018033150732.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2011.01.01/MOD44W.A2011001.h12v05.006.2018033151428.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2011.01.01/MOD44W.A2011001.h11v05.006.2018033150730.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2010.01.01/MOD44W.A2010001.h12v05.006.2018033151424.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2010.01.01/MOD44W.A2010001.h11v05.006.2018033150729.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2009.01.01/MOD44W.A2009001.h11v05.006.2018033150727.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2009.01.01/MOD44W.A2009001.h12v05.006.2018033151423.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2008.01.01/MOD44W.A2008001.h11v05.006.2018033150725.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2008.01.01/MOD44W.A2008001.h12v05.006.2018033151421.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2007.01.01/MOD44W.A2007001.h11v05.006.2018033150724.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2007.01.01/MOD44W.A2007001.h12v05.006.2018033151420.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2006.01.01/MOD44W.A2006001.h11v05.006.2018033150722.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2006.01.01/MOD44W.A2006001.h12v05.006.2018033151419.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2005.01.01/MOD44W.A2005001.h12v05.006.2018033151418.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2005.01.01/MOD44W.A2005001.h11v05.006.2018033150720.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2004.01.01/MOD44W.A2004001.h12v05.006.2018033151417.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2004.01.01/MOD44W.A2004001.h11v05.006.2018033150719.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2003.01.01/MOD44W.A2003001.h11v05.006.2018033150717.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2003.01.01/MOD44W.A2003001.h12v05.006.2018033151415.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2002.01.01/MOD44W.A2002001.h12v05.006.2018033151412.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2002.01.01/MOD44W.A2002001.h11v05.006.2018033150715.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2001.01.01/MOD44W.A2001001.h12v05.006.2018033151410.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2001.01.01/MOD44W.A2001001.h11v05.006.2018033150714.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2000.01.01/MOD44W.A2000001.h12v05.006.2018033151409.hdf
https://e4ftl01.cr.usgs.gov//MODV6_Cmp_B/MOLT/MOD44W.006/2000.01.01/MOD44W.A2000001.h11v05.006.2018033150712.hdf
EDSCEOF