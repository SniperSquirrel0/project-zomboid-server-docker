#!/bin/bash

cd ${STEAMAPP_DIR}

#####################################
#                                   #
# Force an update if the env is set #
#                                   #
#####################################

#echo "Who am i? $(whoami)"

if [ "${FORCEUPDATE}" == "1" ]; then
  echo "FORCEUPDATE variable is set, so the server will be updated right now"
  bash "${STEAMCMD_DIR}/steamcmd.sh" +force_install_dir "${STEAMAPP_DIR}" +login anonymous +app_update "${STEAMAPPID}" validate +quit
fi

######################################
#                                    #
# Process the arguments in variables #
#                                    #
######################################
ARGS=""

# Set the server memory. Units are accepted (1024m=1Gig, 2048m=2Gig, 4096m=4Gig): Example: 1024m
if [ -n "${MEMORY}" ]; then
  ARGS="${ARGS} -Xmx${MEMORY} -Xms${MEMORY}"
fi

# Option to perform a Soft Reset
if [ "${SOFTRESET}" == "1" ] || [ "${SOFTRESET,,}" == "true" ]; then
  ARGS="${ARGS} -Dsoftreset"
fi

# End of Java arguments
ARGS="${ARGS} -- "

# Disables Steam integration on server.
# - Default: Enabled
if [ "${NOSTEAM}" == "1" ] || [ "${NOSTEAM,,}" == "true" ]; then
  ARGS="${ARGS} -nosteam"
fi

# Sets the path for the game data cache dir.
# - Default: ~/Zomboid
# - Example: /server/Zomboid/data
if [ -n "${CACHE_DIR}" ]; then
  ARGS="${ARGS} -cachedir=${CACHE_DIR}"
fi

# Option to control where mods are loaded from and the order. Any of the 3 keywords may be left out and may appear in any order.
# - Default: workshop,steam,mods
# - Example: mods,steam
if [ -n "${MODFOLDERS}" ]; then
  ARGS="${ARGS} -modfolders ${MODFOLDERS}"
fi

# Launches the game in debug mode.
# - Default: Disabled
if [ "${DEBUG}" == "1" ] || [ "${DEBUG,,}" == "true" ]; then
  ARGS="${ARGS} -debug"
fi

# Option to bypasses the enter-a-password prompt when creating a server.
# This option is mandatory the first startup or will be asked in console and startup will fail.
# Once is launched and data is created, then can be removed without problem.
# Is recommended to remove it, because the server logs the arguments in clear text, so Admin password will be sent to log in every startup.
if [ -n "${ADMINPASSWORD}" ]; then
  ARGS="${ARGS} -adminpassword ${ADMINPASSWORD}"
fi

# Server password
if [ -n "${PASSWORD}" ]; then
  ARGS="${ARGS} -password ${PASSWORD}"
fi

# You can choose a different servername by using this option when starting the server.
if [ -n "${SERVERNAME}" ]; then
  ARGS="${ARGS} -servername ${SERVERNAME}"
else
  # If not servername is set, use the default name in the next step
  SERVERNAME="servertest"
fi

# If preset is set, then the config file is generated when it doesn't exists or SERVERPRESETREPLACE is set to True.
if [ -n "${SERVERPRESET}" ]; then
  # If preset file doesn't exists then show an error and exit
  if [ ! -f "${STEAMAPP_DIR}/media/lua/shared/Sandbox/${SERVERPRESET}.lua" ]; then
    echo "*** ERROR: the preset ${SERVERPRESET} doesn't exists. Please fix the configuration before start the server ***"
    exit 1
  # If SandboxVars files doesn't exists or replace is true, copy the file
  elif [ ! -f "${HOME_DIR}/Zomboid/Server/${SERVERNAME}_SandboxVars.lua" ] || [ "${SERVERPRESETREPLACE,,}" == "true" ]; then
    echo "*** INFO: New server will be created using the preset ${SERVERPRESET} ***"
    echo "*** Copying preset file from \"${STEAMAPP_DIR}/media/lua/shared/Sandbox/${SERVERPRESET}.lua\" to \"${HOME_DIR}/Zomboid/Server/${SERVERNAME}_SandboxVars.lua\" ***"
    mkdir -p "${HOME_DIR}/Zomboid/Server/"
    cp -nf "${STEAMAPP_DIR}/media/lua/shared/Sandbox/${SERVERPRESET}.lua" "${HOME_DIR}/Zomboid/Server/${SERVERNAME}_SandboxVars.lua"
    sed -i "1s/return.*/SandboxVars = \{/" "${HOME_DIR}/Zomboid/Server/${SERVERNAME}_SandboxVars.lua"
    # Remove carriage return
    dos2unix "${HOME_DIR}/Zomboid/Server/${SERVERNAME}_SandboxVars.lua"
    # I have seen that the file is created in execution mode (755). Change the file mode for security reasons.
    chmod 644 "${HOME_DIR}/Zomboid/Server/${SERVERNAME}_SandboxVars.lua"
  fi
fi

# Option to handle multiple network cards. Example: 127.0.0.1
if [ -n "${IP}" ]; then
  ARGS="${ARGS} ${IP} -ip ${IP}"
fi

# Set the DefaultPort for the server. Example: 16261
if [ -n "${PORT}" ]; then
  ARGS="${ARGS} -port ${PORT}"
fi

# Option to enable/disable VAC on Steam servers. On the server command-line use -steamvac true/false. In the server's INI file, use STEAMVAC=true/false.
if [ -n "${STEAMVAC}" ]; then
  ARGS="${ARGS} -steamvac ${STEAMVAC,,}"
fi

# Steam servers require two additional ports to function (I'm guessing they are both UDP ports, but you may need TCP as well).
# These are in addition to the DefaultPort= setting. These can be specified in two ways:
#  - In the server's INI file as SteamPort1= and SteamPort2=.
#  - Using STEAMPORT1 and STEAMPORT2 variables.
if [ -n "${STEAMPORT1}" ]; then
  ARGS="${ARGS} -steamport1 ${STEAMPORT1}"
fi
if [ -n "${STEAMPORT2}" ]; then
  ARGS="${ARGS} -steamport2 ${STEAMPORT1}"
fi

########################################
#                                      #
# Process the .ini file from variables #
#                                      #
########################################
RCON_PORT="${RCON_PORT:="16269"}"
RCON_PASSWORD="${RCON_PASSWORD:="${SERVERNAME}_password_${RCON_PORT}"}"

# sets if server is publicly visibile
if [ -n "${PUBLIC}" ]; then
	sed -i -E "s/^Public=.*$/Public=${PUBLIC}/" "${HOME_DIR}/Zomboid/Server/${SERVERNAME}.ini"
else
	sed -i -E "s/^Public=.*$/Public=false/" "${HOME_DIR}/Zomboid/Server/${SERVERNAME}.ini"
fi
if [ -n "${PUBLIC_NAME}" ]; then
	sed -i -E "s/^PublicName=.*$/PublicName=${PUBLIC_NAME}/" "${HOME_DIR}/Zomboid/Server/${SERVERNAME}.ini"
fi
if [ -n "${PUBLIC_DESCRIPTION}" ]; then
	sed -i -E "s/^PublicDescription=.*$/PublicDescription=\"${PUBLIC_DESCRIPTION}\"/" "${HOME_DIR}/Zomboid/Server/${SERVERNAME}.ini"
fi

if [ -n "${PASSWORD}" ]; then
	sed -i -E "s/^Password=.*$/Password=${PASSWORD}/" "${HOME_DIR}/Zomboid/Server/${SERVERNAME}.ini"
fi

if [ -n "${RCON_PASSWORD}" ]; then
	sed -i -E "s/^RCONPassword=.*$/RCONPassword=${RCON_PASSWORD}/" "${HOME_DIR}/Zomboid/Server/${SERVERNAME}.ini"
fi

if [ -n "${RCON_PORT}" ]; then
	sed -i -E "s/^RCONPort=.*$/RCONPort=${RCON_PORT}/" "${HOME_DIR}/Zomboid/Server/${SERVERNAME}.ini"
fi

if [ -n "${MOD_IDS}" ]; then
 	echo "*** INFO: Found Mods including ${MOD_IDS} ***"
    MOD_IDS_SANTIZED="$(printf "$MOD_IDS\n" | sed -e "s/&/\\\&/g")"
	sed -i -E "s/^Mods=.*/Mods=${MOD_IDS_SANTIZED}/g" "${HOME_DIR}/Zomboid/Server/${SERVERNAME}.ini"
fi

if [ -n "${WORKSHOP_IDS}" ]; then
 	echo "*** INFO: Found Workshop IDs including ${WORKSHOP_IDS} ***"
	sed -i -E "s/^WorkshopItems=.*/WorkshopItems=${WORKSHOP_IDS}/" "${HOME_DIR}/Zomboid/Server/${SERVERNAME}.ini"
fi

#############################################
#                                           #
# Process the rcon.yaml file from variables #
#                                           #
#############################################
RCON_CONFIG_FILE="${HOME_DIR}/rcon.yaml"
if [ -f "${RCON_CONFIG_FILE}" ]; then
    sed -i -E "s/address: \".*$/address: \"127.0.0.1:${RCON_PORT}\"/" "${RCON_CONFIG_FILE}"
    sed -i -E "s/password: \".*$/password: \"${RCON_PASSWORD}\"/" "${RCON_CONFIG_FILE}" 
    sed -i -E "s/log: \".*$/log: \"rcon-${SERVERNAME}\"/" "${RCON_CONFIG_FILE}"
    sed -i -E "s/type: \".*$/type: \"rcon\"/" "${RCON_CONFIG_FILE}"
    [ -z "$(grep -i "rcon" "${RCON_CONFIG_FILE}")" ] && echo 'alias rcon=rcon -c $HOME/rcon.yaml' >> "${HOME_DIR}/.bashrc"
fi

###############################
#                             #
# Search_folder.sh processing #
#                             #
###############################

# Fixes EOL in script file for good measure
sed -i 's/\r$//' /server/scripts/search_folder.sh
# Check 'search_folder.sh' script for details
if [ -e "${HOME_DIR}/pz-dedicated/steamapps/workshop/content/108600" ]; then

  map_list=""
  source /server/scripts/search_folder.sh "${HOME_DIR}/pz-dedicated/steamapps/workshop/content/108600"
  map_list=$(<"${HOME_DIR}/maps.txt")  
  rm "${HOME_DIR}/maps.txt"

  if [ -n "${map_list}" ]; then
    echo "*** INFO: Added maps including ${map_list} ***"
    sed -i "s/Map=.*/Map=${map_list}Muldraugh, KY/" "${HOME_DIR}/Zomboid/Server/${SERVERNAME}.ini"

    # Checks which added maps have spawnpoints.lua files and adds them to the spawnregions file if they aren't already added
    IFS=";" read -ra strings <<< "$map_list"
    for string in "${strings[@]}"; do
        if ! grep -q "$string" "${HOME_DIR}/Zomboid/Server/${SERVERNAME}_spawnregions.lua"; then
          if [ -e "${HOME_DIR}/pz-dedicated/media/maps/$string/spawnpoints.lua" ]; then
            result="{ name = \"$string\", file = \"media/maps/$string/spawnpoints.lua\" },"
            sed -i "/function SpawnRegions()/,/return {/ {    /return {/ a\
            \\\t\t$result
            }" "${HOME_DIR}/Zomboid/Server/${SERVERNAME}_spawnregions.lua"
          fi
        fi
    done
  fi 
fi

# Fix to a bug in start-server.sh that causes to no preload a library:
# ERROR: ld.so: object 'libjsig.so' from LD_PRELOAD cannot be preloaded (cannot open shared object file): ignored.
export LD_LIBRARY_PATH="${STEAMAPP_DIR}/jre64/lib:${LD_LIBRARY_PATH}"

## Fix the permissions in the data and workshop folders
chown -R 1000:1000 /home/steam/pz-dedicated/steamapps/workshop /home/steam/Zomboid

export LD_LIBRARY_PATH=\"${STEAMAPP_DIR}/jre64/lib:${LD_LIBRARY_PATH}\" && cd ${STEAMAPP_DIR} && pwd && ./start-server.sh ${ARGS}
#su - steam -c "export LD_LIBRARY_PATH=\"${STEAMAPP_DIR}/jre64/lib:${LD_LIBRARY_PATH}\" && cd ${STEAMAPP_DIR} && pwd && ./start-server.sh ${ARGS}"
