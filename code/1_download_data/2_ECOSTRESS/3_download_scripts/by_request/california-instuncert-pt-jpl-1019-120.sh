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
    read -p "Username (annaboser): " username
    username=${username:-annaboser}
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
    echo "https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/ed3d486e-0903-484c-a961-588987968e8c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019032222727_aid0001.tif"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/ed3d486e-0903-484c-a961-588987968e8c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019032222727_aid0001.tif -w %{http_code} | tail  -1`
    if [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w %https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/ed3d486e-0903-484c-a961-588987968e8c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019032222727_aid0001.tif | tail -1)
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
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/8c0f990d-ccf7-4374-ac87-11b812e3aaf1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019274230422_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/64be2114-6bcf-4d9b-8926-63abf48278e9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019274230514_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/b519424d-cd1c-42bf-8fb9-c3e757a8036e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019275221558_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/fecef4b9-00e8-4eaf-9071-228dbd43ddba/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019276212727_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/6aa7c14c-c7d0-4ca1-a67c-40ee8a962917/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019276212819_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/6e375dc6-6121-4db9-95a6-31f2de621d94/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019277203903_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/a23409c7-b517-468a-a9c7-0205bd30369d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019277203955_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/c236b9d4-04d4-4864-b806-c6ee41ac4494/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019277221641_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/6fb10c20-72eb-4d8a-8e93-5be95f84d871/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019278212715_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/c2eb1155-dd42-40a5-a70b-8b718a973e70/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019278212807_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/582a05c4-9722-40c9-ac9b-acdbd68b6f58/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019279203840_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/ace3916a-725e-4e62-867e-a987c1fa949d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019279203932_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/a439f035-2d4c-46d0-8c3d-ec569b3283e6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019280195010_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/a952fa28-04a3-42e4-923e-bd944e719101/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019281190155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/22807b17-089f-4b59-9c9c-d019fa420633/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019281203826_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/8a87eb80-d3cd-487f-8187-4e9f9652b5ed/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019281203918_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/3adb5e0a-3f40-4e64-bde6-83773bf408ac/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019282194945_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/70794abe-c323-4c62-a153-f5a162b46ff4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019282195037_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/b71e17ad-6b72-4d20-9390-33bfc98608b0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019287004118_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/9fdad943-f76d-4a2b-8043-9290d9b29042/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019287004210_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/e0d89ae8-2566-4cf9-b2ab-7965d916fd3a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019287004302_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/9750fbfb-3718-479b-ae3a-37c8a73ac347/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019287004354_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/f0ba97e0-f79a-44b9-9595-bc2bc4c8d32f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019287004446_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/3bce0e5c-9e4d-4904-a07a-4eaef45e9baa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019287172335_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/8bcd27bc-24d3-4a6a-b6ac-161f6b9ef648/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019287172427_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/7d498ae3-7a65-435d-a7a0-2e8c6eb577a9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019288163504_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/2f6a823a-6ea1-49d0-bbda-3df3cda36c02/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019288163556_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/68c8d067-0e0f-40ab-835f-ae3e6cc5fad0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019289154701_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/0bdfa47a-f09b-44dc-81aa-ce052d0063ec/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019289235304_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/fbdd170a-f8ba-4614-b59f-4440643ca31e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019289235356_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/95e32ebf-2258-45dc-8299-2c9f6687110d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019289235448_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/acde9472-b165-4d0d-88d0-0d56ec3b10ec/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019289235540_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/efdef770-bc74-45d7-8491-8be76f59629d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019290163442_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/e3c60a63-74c0-47f7-9434-d55d9de11b70/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019290230400_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/61f98130-cdcb-49ec-81b5-c5d833bfe612/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019290230452_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/146bd05e-de94-41dc-b010-49cc72ebba38/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019290230636_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/f6452d8b-51b2-4230-aa6d-ae29a00e0c5a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019291154604_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/867bf001-e692-479d-8956-63ba1b8e9c58/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019291154656_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/e29fdd15-ddf8-47b1-b9a8-4f0b0e256d23/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019291221534_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/42c54e16-98df-416b-aa88-a7c681e06282/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019292145735_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/62c991b3-a222-468a-bd36-185d0cacbfb1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019292145827_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/43fe6b9c-439a-408b-b1ec-e64ede75be42/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019293140924_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/f89dd4e1-7ccf-4995-adcd-3054666c25ce/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019293154543_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/614d72e9-1b8c-47e2-98e8-7fac5dead190/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019293154635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/3fdbd1ac-5f6b-4dd3-825c-9901b576db60/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019294145708_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/59d3bb82-50f5-4a54-b8a7-4242a0603e30/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019294212719_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/3e8492dc-f0eb-4be1-ba18-cb8f570749c4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019294212811_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/253021f9-2108-42d7-b93e-3decc36474e4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019294212903_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/9a1c17b6-c128-4525-b722-2006c5923088/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019295140923_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/15e8f1f7-e918-4827-975b-3c3ef828504a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019295203814_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/781b9747-f4c7-4436-9c9e-b25fdcd8fcfc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019296212741_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/113f67e8-4d8f-40ec-9231-65b8211ba84b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019296212833_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/2dfd057e-a5bf-40e3-8d29-2e7da6a284a5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019298194939_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/12e1d5db-c092-4573-b81b-a4b4fdf0217e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019298195031_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/2aa85a53-da71-48b7-87d6-6b01e8bf7a68/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019298195123_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/ba81e648-16db-473a-892d-b5c0e1dce4cd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019299190038_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/5c91fd94-2b8c-4a64-9a9b-ea06889a18b9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019300194922_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/3f2e7431-a928-4bbf-b86b-71ab136246e2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019300195014_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/cdb30cff-ba23-4748-8bad-6f6a16f6e948/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019300195106_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/5ce67b3e-8d7c-4aa3-88ad-ff6d43c9cc5e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019301190107_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/3254894d-daeb-436d-a868-720589fcb96e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019301190159_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/8cb1ab83-6039-4a97-b1c2-4bc7712a604e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019301190250_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/c9f17eea-9e6e-4b79-b946-b8e34fc603a0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019302181155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/000fc765-d933-42f5-8da4-3ceee821770b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019302181247_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/8dec1e9a-b372-4702-8b5a-20762bfc596d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019303172324_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/e6fe7c71-0113-4285-b6fe-f2fad9c6591c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019305172233_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/08c7c2d5-7964-4f31-a5cd-c155992f3377/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019305172325_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/c680d9c7-627d-4da4-8560-f0e5aa8b971a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019306163354_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/d714e351-a688-4e24-816f-c9d9b5679a10/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019306163446_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/224b3d13-1221-4b65-ac70-744f00c3216c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019308163555_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/5eef70fe-d462-4dc9-b1b6-23b01471f884/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019309154439_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/35ae7146-a4d7-4d68-b458-ef859e392c8e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019309154531_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/b01d400b-7047-4626-b959-cc88b19ab1d4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019309154623_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/0520636d-5f54-4eb5-9052-a6588e5b15b9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019309154715_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/2416f2cc-93af-4406-9142-188862f297e5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019310145607_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/9b5c66e0-b542-4dc8-9eed-8b9a561931a0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019313141025_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/b141efd6-de1a-4cee-98cd-c932ab778b8d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019330002148_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/1bdf9be4-f63b-4fc8-bffb-a279cf2ee568/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019330233341_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/c08161a2-9ccb-44b6-ac75-d9652b8adfda/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019330233433_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/b9f7cc6c-d561-4c76-acee-11cb90004759/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019332002207_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/bcbe2603-7c63-4078-88f8-23aae8626b5b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019333224453_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/841eef67-09c1-432d-b540-0e6ad2ad3124/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019333224545_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/048843c7-048e-4cf0-88da-2c572f45443a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019334215658_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/3db54f70-48ad-4319-9161-f55cf702d585/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019336215612_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/900d04e9-48f1-4be0-af0e-2b55574051f7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019336215704_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/51ccbee0-50d1-42bf-8ec6-5a802787c5a9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019338215652_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/3f69f04c-c671-4e63-bee1-4bb467b0dfd6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019339210741_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/e6ae93ce-1135-4d95-b296-4529edbc761b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019340201909_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/e22ac761-8111-4090-ab49-a890a4480acf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019340202001_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/42f576d7-d2cd-49e5-9077-8fea9c3b0d8b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019342201907_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/a68a1855-0747-4b57-a070-89a22e29b3ba/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019342201959_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/c09b6f6d-bd0a-444b-96b7-f2044f7dd4bc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019343193029_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/248dc4d6-3590-4121-a443-111ef7cd4075/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019343193121_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/a9f304bf-4b5e-4bff-8fff-a6324d1ee5a1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019344184205_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/f3acfa97-079e-43b1-9636-9c742f1b975e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019345175341_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/b4a0785e-a91e-4d1d-9502-d4b9d1499a4f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019345175433_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/8d6ba9d3-ca42-4198-a6c8-1130d7290134/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019349161631_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/844d8412-b7ad-47c5-82f5-3fb20d604f60/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019350002413_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/289b0ae0-8473-4226-9a0c-46516b5e4ea2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019350002505_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/5118d42b-5830-43c4-b78c-257ab3a685f1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019350233514_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/bed9218c-b96e-4cc5-88be-201c3251a50d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019350233606_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/ad8cfea4-66d3-4d96-a4cb-0e9415474613/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019350233658_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/8980ebdc-5b37-4c44-b89b-cb5c8b5a86ab/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019352152728_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/f2b86186-eef0-489b-a49a-3e3fac6b9048/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019352152820_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/08c0762c-f844-447b-85ff-1761af6e4887/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019353143942_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/a3ef1a62-7ae8-4abd-8018-8a0327d972e6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019359193155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/9122e462-ed15-4b97-b84f-00f14c1090d7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019365175734_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/d03b4ab8-d296-4132-a841-1bbbea68597f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019365175826_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/8a57ac6b-9315-481d-a905-7b3de312d2b2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019365175918_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/1e613679-988a-411c-96cb-812fb110ccea/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020001170836_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/45c89361-da97-4b7f-866d-98fd1c4a6dc4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020001170928_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/eaa339cb-a101-4282-840d-dc8376733d44/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020001171020_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/ba41d6af-e3d6-419b-9e7e-adadc67b41ce/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020001171112_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/a52d6528-7293-4ae3-bf84-b5c5798ad520/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020005153413_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/28c821fe-f264-4b70-82ff-e8658e301bf6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020005153505_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/a1c4db71-c2fb-4524-bcaf-93c3d8920efb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020005153557_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/bcf921e2-ef15-4f1a-ac51-e3109e857f6a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020025010824_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/33111020-9031-410b-8bf0-5dbf39be7cfa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020026002103_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/24ed9d0c-8765-43a9-9952-5dbafb7f950b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020026002155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/c9c5ca58-c48a-472d-b57f-c53fed63d7b5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020026233348_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/29db8ece-5e61-48eb-b891-5fd88ccbe07c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020026233440_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/704807e6-800f-4aaf-9c6f-b49a3b3a5747/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020028233509_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/fb7a4ae0-bb7a-4486-ac41-4f60980c882e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020029224753_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/5ca4e235-cfd0-4bcf-acce-7333d8ce0057/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020029224845_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/a69dcbb4-a7e4-4e54-9c6d-7e2d9a7436e5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020030220024_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/e73c22d4-c96f-4895-9808-dab99ce2df69/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020030220116_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/83d55c5f-dda6-42d5-8229-ecd4313fb8f5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020031225003_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/bdae2e2f-9639-4eee-9347-9cdee4df3488/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019274230422_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/53251d12-13a0-4e5b-8127-9a75518daff9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019274230514_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/e392b387-e0b6-4127-8837-ee1393de04f7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019275221558_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/47dfe460-eb90-4b12-a3be-3c04e56da5fd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019276212727_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/f4ddba99-7d19-4cc1-8cfc-d116de4a78fa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019276212819_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/0045ffd0-ec61-4d76-a76b-9ea7bc046c0d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019277203903_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/85aacce2-bf38-4cbb-a954-c68bdc83034e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019277203955_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/d5e7cc6b-c584-4add-8a91-197dcf0d17e9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019277221641_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/80044b4f-42bd-4b06-af67-33403bf7824b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019278212715_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/eefa33ce-806b-47e4-9b32-11278cc888c0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019278212807_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/fe6f8944-a976-47b7-8fb4-61691b050e18/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019279203840_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/54713813-2434-42b3-8cfe-bfdbde54f426/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019279203932_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/f422e4bf-0cb8-406c-9ef0-a4c08f820fa3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019280195010_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/27f54cd8-8f1f-4298-a501-a63ddac4a725/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019281190155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/b660072c-6744-4ba9-9560-0aee0ed89f44/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019281203826_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/8b9a6501-a45a-42ea-b982-06af332e8bd1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019281203918_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/e437546f-d74c-4d71-9c9b-ff34c47e6857/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019282194945_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/9f761081-39f0-4e1e-b9c7-b4bfc322f580/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019282195037_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/a00206cd-2d46-429b-872b-083a84b4e0c9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019287004118_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/8b97ff25-11c7-4b03-b81b-94a2b8d42d74/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019287004210_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/2dd4717f-a7fd-4bc8-b676-a77bfdcbfe4d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019287004302_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/0cd416e8-5c53-43a4-b5df-9e2928b6e06b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019287004354_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/93ec3a1a-f4e9-4e0e-97eb-3f53c5eefbbe/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019287172335_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/dac05ebf-4daa-428a-acd9-d426cbdd9805/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019287172427_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/a95a27c1-ba98-40f6-9b91-9fa89232ee70/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019288163504_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/145f9c09-711e-46d7-8f46-46dca9f57329/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019288163556_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/ef5ede80-e14c-4dfe-8613-41c2b7d2ce9f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019289154701_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/85fcd0e7-a744-4271-8ca5-c8c5da8c28bb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019289235304_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/a5c0e5fc-8987-48ae-b57e-f52b65ff6c06/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019289235356_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/b629975d-56c4-4e06-b113-043709843110/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019289235448_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/67920d93-7797-45ba-9c6b-1bfb668ea88f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019289235540_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/4e814fc5-0bc8-48f2-8d6f-239715eea794/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019290163442_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/24d39f5c-224b-4f93-a1a0-b17358f212b4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019290230400_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/da734c9e-2838-4f84-9901-fdcc348d9cf2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019290230452_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/8cb4b941-9c62-449d-8bfa-1977a9912946/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019290230636_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/cd07b088-3015-4ba7-81f0-133baea4840e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019291154604_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/71049982-0ba9-4e37-8fae-84bb9f926db5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019291154656_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/9b7c2f56-414a-4399-9b6e-dff29a1c173d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019291221534_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/2a622077-d1e8-4743-99b6-af011dbc04d2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019292145735_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/8ce2df85-8ff6-4d8a-aa2c-6312bacc0632/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019292145827_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/d7c0b0b4-5a32-4294-95f7-c82382e26abf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019293140924_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/95f900e5-2959-43ed-81a4-8c849169eb32/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019293154543_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/2cb1e374-00fb-4b8e-88ae-25632bf74d8c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019293154635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/66f3554c-26f4-4478-a746-17d30bc40f19/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019294145708_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/bc3e7f7f-6462-4acf-b6e2-db42a84cc5a4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019294212719_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/679be514-469b-478a-8249-3565ac7458de/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019294212811_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/91a5c3f6-9448-43a2-9de4-a72cebe9fdfc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019294212903_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/118cd415-c7d5-482e-822e-27167146ce0f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019295140923_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/44653db0-92f7-4955-9c42-873f069e4ff7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019295203814_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/f5baeba8-8d9d-4a25-8cfd-525ca79cbb44/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019296212741_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/a91411d9-d5c0-41f0-a45f-8c1b5b890cbd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019296212833_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/5114e20a-2f09-47a0-be64-e0c2a2aef5e1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019298194939_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/9c0a22b4-05be-433c-b4df-62c21f47a811/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019298195031_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/afed390a-c626-4541-a186-08eb7de21bdb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019298195123_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/6ddeb067-5d0b-4b41-ac13-ef3fe3ecb307/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019299190038_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/d4a60be9-ed12-4db7-a1f3-303eab54100a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019300194922_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/6e2f45d1-427a-4295-bee4-6f65baf9c50c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019300195014_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/a5025721-6012-4117-a6ce-aa7adb8f54c2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019300195106_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/dcc2697d-e56c-42d1-bf46-157797cc0da1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019301190107_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/1389177a-5f05-430c-b284-ab4125d0d131/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019301190159_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/9355157a-3096-4b49-a13f-23463e300e01/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019301190250_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/97512294-99f3-44fb-a41e-64ff6f156c12/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019302181155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/74c1eb5b-d8a4-4aff-b907-1c8dbb172cf0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019302181247_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/7e1f8635-0601-452b-954d-daf6be5c34a3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019303172324_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/d841e8b1-3434-43c4-a295-2223d221073e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019305172233_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/568b72c3-58bc-4865-b58e-a4c4230ec174/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019305172325_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/32ce397b-cc78-46e1-b96e-c1b2458fceea/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019306163354_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/3eb93954-be2b-47ba-abeb-8707b0dbdb8f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019306163446_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/8f41201e-f9bd-4a97-a4dc-bf4431f6cb0a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019308163555_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/4765c270-315c-4136-a579-cae5c0b261f2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019309154439_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/0a1cde41-fc33-4111-a1bf-1fcd62e2f139/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019309154531_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/ac208857-00d5-43d8-9e73-bb4f1df4a832/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019309154623_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/34f3c255-0ac2-48db-a565-70b2fde3058c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019309154715_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/8983bd78-f0b1-4d54-b0ec-367722c2bfb7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019310145607_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/30344ca9-07a5-48f9-86c6-2d442e041dcf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019313141025_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/05016747-be89-42d6-bb86-a6ac1a7b5de1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019330002148_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/72b996d1-a7f7-4a36-9676-a7d6871bf3a4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019330233341_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/89bfff5c-9094-48c6-84f4-c291bffddb9c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019330233433_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/97977184-492a-414e-be86-c7e2cd7a061d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019332002207_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/aa820147-3bb5-4388-9429-01df37843be7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019333224453_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/853d454e-7a8b-4a3c-a375-a51f5e4da24b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019333224545_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/39e5fac9-0bfe-45d2-a253-6fb097d2cd23/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019334215658_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/b6b29016-4899-44e5-8aff-3f61d39c52ee/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019336215612_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/fd18f5bd-e8eb-4b96-a7b8-e3c0eaa87841/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019336215704_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/5b8bef21-2e67-4033-8a1c-8858d2caa48c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019338215652_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/59a20d21-4e24-4c21-80bf-2c477a266e72/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019339210741_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/134be793-9e67-4e64-8c04-be287ca5431f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019340201909_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/e4768177-e5cc-4089-991f-d93bbd8b3463/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019340202001_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/b50835bf-cb53-4bbd-85bc-b67ca9aa1b59/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019342201907_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/e72eecc3-f7cd-4ca1-9f81-ddf7cf202ceb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019342201959_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/92f52149-2fa1-4c08-82ed-ff5fcfce7557/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019343193029_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/7f633c91-978e-4489-b238-b2baa557b4a3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019343193121_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/7276e19f-c081-491c-9e59-07abbfd350c7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019344184205_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/d636693d-ad52-4b72-ae49-1c6ea65547cb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019345175341_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/5e943a06-7e0e-486e-90ab-b2020407ce6e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019345175433_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/e551a16b-9899-490a-b768-c8f1dbdb14cf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019349161631_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/1bc66b37-46cd-472a-b380-af15678283a2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019350002413_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/11a174a7-fa18-4abc-bffb-1b75395d3883/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019350002505_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/d0012790-e043-480c-b6cd-fe81a21a200c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019350233514_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/dba89b11-964d-4fe3-8f1d-679d5c773322/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019350233606_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/d6b62d26-6880-4488-9861-0c784fd1898b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019350233658_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/86060a06-242c-4fca-962e-77990b1b73b0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019352152728_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/1f3a8b42-ccc8-4eb1-a0e0-5ca1beaee213/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019352152820_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/913c3b6c-2b60-4383-ad05-a32f546d625e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019353143942_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/d17bf0ae-8176-449d-be04-44feb593a19e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019359193155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/7532a277-538f-448c-b4e9-43600f9928f0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019365175734_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/31a42e2a-8c84-49fd-aba4-d19b410d8369/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019365175826_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/7235b11b-6ca6-41d0-b7d4-7b3c656a7b92/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019365175918_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/b002cafe-47b6-4696-a94c-47327798bb55/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020001170836_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/98d2965c-8e22-4503-94ca-69aaa980e970/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020001170928_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/ed845687-8f38-42b3-adbb-a913a8d51060/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020001171020_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/5793a2f2-cf0b-4b56-a9d3-c7e6ff4e70a8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020001171112_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/db8c04b2-6238-49bb-9a7b-226b61abd3d1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020005153413_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/95c772a7-efe9-45e7-9be9-e4e112165e5d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020005153505_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/28f72639-5e45-42f4-a8c8-265232fa31f4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020005153557_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/46c91f85-ef62-4532-a7c9-2f58f631c71d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020025010824_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/c33595df-4430-4fba-8cfb-90e1f92e911d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020026002103_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/6245b63a-4a35-4fe4-8bea-adf95486bedf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020026002155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/c1f0af57-bc8b-4c74-8fc1-2e966fe25077/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020026233348_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/469c8fb3-d6a0-4311-97c6-96e3a75ababd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020026233440_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/533b40ed-d6d7-47bb-9be2-bed6c151c7f9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020028233509_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/90385676-0e75-4a80-a4f1-059d66cccb31/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020029224753_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/0823132c-7268-4212-8e65-e70401b47692/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020029224845_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/8e778980-2fa4-4e28-bf1b-7a2b34d6064e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020030220024_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/b84d8d01-9b10-4fbd-97c9-70ec7d681f7e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020030220116_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/881f58a6-2dda-4fa8-bde2-0acc4a421cd5/f5ee7df4-82e4-4868-890a-11dd87d519f5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020031225003_aid0001.tif
EDSCEOF