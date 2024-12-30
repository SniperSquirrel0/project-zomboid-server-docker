###########################################################
# Dockerfile that builds a ProjectZomboid Gameserver
########################################################### 
FROM cm2network/steamcmd:root

LABEL maintainer="acorn.vault.email@gmail.com"

ENV USER="steam"
ENV HOME_DIR="/home/${USER}"
ENV DATA_DIR="${HOME_DIR}"
ENV STEAMAPPID=380870
ENV STEAMAPP="pz"
ENV STEAMAPP_DIR="${DATA_DIR}/${STEAMAPP}-dedicated"
ENV STEAMCMD_DIR="${DATA_DIR}/steamcmd"

# Install required packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
      dos2unix \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* ;

# Ensuring user exists
RUN mkdir -p "${HOME_DIR}" "${DATA_DIR}" "${STEAMAPP_DIR}" "${STEAMCMD_DIR}" \
    && chown -R "${USER}:${USER}" "${HOME_DIR}" "${DATA_DIR}" "${STEAMAPP_DIR}"

USER ${USER}

# Download the Project Zomboid dedicated server app using the steamcmd app
# Set the entry point file permissions
RUN "${STEAMCMD_DIR}/steamcmd.sh" +force_install_dir "${STEAMAPP_DIR}" \
                                    +login anonymous \
                                    +app_update "${STEAMAPPID}" validate \
                                    +quit ;
USER root

# Copy the entry point file
COPY --chown=${USER}:${USER} scripts/entry.sh /server/scripts/entry.sh
RUN chmod 550 /server/scripts/entry.sh ;

# Copy searchfolder file
COPY --chown=${USER}:${USER} scripts/search_folder.sh /server/scripts/search_folder.sh
RUN chmod 550 /server/scripts/search_folder.sh ;

USER ${USER}

# Create required folders to keep their permissions on mount
RUN mkdir -p "${DATA_DIR}/Zomboid" ;

WORKDIR ${DATA_DIR}
# Expose ports
EXPOSE 16261-16262/udp \
       27015/tcp

USER root
#ENTRYPOINT ["/bin/bash"]
ENTRYPOINT ["/server/scripts/entry.sh"]
