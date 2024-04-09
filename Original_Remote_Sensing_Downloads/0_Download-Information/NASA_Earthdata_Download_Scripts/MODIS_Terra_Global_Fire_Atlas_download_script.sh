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
    echo "https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2016.tif"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2016.tif -w '\n%{http_code}' | tail  -1`
    if [ "$approved" -ne "200" ] && [ "$approved" -ne "301" ] && [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w '\n%{http_code}' https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2016.tif | tail -1)
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
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2016.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2016.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2016.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2016.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2016.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2016.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2016.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2016.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2016.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2016.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2016.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2016.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2016.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2016.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2016.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2016.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2016.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2016.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2016.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2016.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2016.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2016.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2016.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2016.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2016.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2016.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2015.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2015.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2015.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2015.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2015.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2015.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2015.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2015.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2015.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2015.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2015.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2015.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2015.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2015.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2015.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2015.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2015.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2015.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2015.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2015.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2015.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2015.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2015.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2015.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2015.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2015.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2014.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2014.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2014.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2014.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2014.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2014.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2014.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2014.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2014.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2014.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2014.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2014.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2014.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2014.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2014.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2014.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2014.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2014.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2014.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2014.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2014.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2014.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2014.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2014.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2014.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2014.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2013.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2013.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2013.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2013.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2013.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2013.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2013.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2013.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2013.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2013.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2013.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2013.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2013.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2013.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2013.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2013.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2013.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2013.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2013.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2013.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2013.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2013.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2013.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2013.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2013.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2013.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2012.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2012.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2012.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2012.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2012.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2012.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2012.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2012.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2012.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2012.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2012.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2012.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2012.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2012.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2012.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2012.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2012.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2012.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2012.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2012.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2012.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2012.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2012.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2012.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2012.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2012.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2011.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2011.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2011.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2011.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2011.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2011.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2011.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2011.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2011.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2011.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2011.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2011.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2011.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2011.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2011.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2011.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2011.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2011.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2011.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2011.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2011.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2011.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2011.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2011.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2011.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2011.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2010.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2010.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2010.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2010.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2010.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2010.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2010.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2010.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2010.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2010.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2010.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2010.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2010.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2010.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2010.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2010.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2010.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2010.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2010.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2010.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2010.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2010.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2010.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2010.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2010.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2010.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2009.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2009.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2009.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2009.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2009.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2009.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2009.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2009.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2009.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2009.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2009.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2009.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2009.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2009.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2009.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2009.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2009.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2009.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2009.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2009.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2009.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2009.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2009.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2009.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2009.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2009.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2008.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2008.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2008.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2008.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2008.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2008.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2008.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2008.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2008.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2008.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2008.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2008.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2008.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2008.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2008.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2008.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2008.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2008.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2008.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2008.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2008.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2008.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2008.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2008.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2008.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2008.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2007.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2007.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2007.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2007.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2007.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2007.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2007.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2007.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2007.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2007.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2007.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2007.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2007.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2007.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2007.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2007.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2007.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2007.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2007.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2007.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2007.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2007.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2007.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2007.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2007.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2007.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2006.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2006.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2006.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2006.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2006.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2006.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2006.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2006.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2006.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2006.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2006.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2006.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2006.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2006.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2006.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2006.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2006.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2006.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2006.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2006.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2006.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2006.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2006.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2006.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2006.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2006.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2005.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2005.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2005.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2005.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2005.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2005.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2005.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2005.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2005.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2005.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2005.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2005.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2005.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2005.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2005.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2005.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2005.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2005.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2005.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2005.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2005.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2005.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2005.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2005.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2005.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2005.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2004.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2004.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2004.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2004.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2004.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2004.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2004.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2004.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2004.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2004.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2004.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2004.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2004.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2004.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2004.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2004.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2004.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2004.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2004.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2004.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2004.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2004.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2004.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2004.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2004.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2004.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2003.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_monthly_2003.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2003.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_ignitions_monthly_2003.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2003.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_yearly_2003.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2003.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_ignitions_2003.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2003.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_size_monthly_2003.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2003.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_duration_monthly_2003.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2003.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_yearly_2003.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2003.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_spread_monthly_2003.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2003.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_day_of_burn_yearly_2003.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2003.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_fire_line_monthly_2003.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2003.zip
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_V1_perimeter_2003.zip.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2003.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_direction_yearly_2003.tif.sha256
https://data.ornldaac.earthdata.nasa.gov/protected/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2003.tif
https://data.ornldaac.earthdata.nasa.gov/public/cms/CMS_Global_Fire_Atlas/data/Global_fire_atlas_speed_monthly_2003.tif.sha256
EDSCEOF