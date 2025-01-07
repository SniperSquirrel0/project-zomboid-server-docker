###########################################################
# Dockerfile that builds a ProjectZomboid Gameserver
########################################################### 
FROM cm2network/steamcmd:root

# hook into docker BuildKit --platform support
# see https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

ARG APPS_REV=1
ARG GITHUB_BASEURL=https://github.com

ENV USER="steam"
ENV HOME_DIR="/home/${USER}"
ENV DATA_DIR="${HOME_DIR}"
ENV STEAMAPPID=380870
ENV STEAMAPP="pz"
ENV STEAMAPP_DIR="${DATA_DIR}/${STEAMAPP}-dedicated"
ENV STEAMCMD_DIR="${DATA_DIR}/steamcmd"
# Define the version of rcon-cli to install

# Install required packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
      dos2unix \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* ;

ARG EASY_ADD_VERSION=0.8.8
ADD ${GITHUB_BASEURL}/itzg/easy-add/releases/download/${EASY_ADD_VERSION}/easy-add_${TARGETOS}_${TARGETARCH}${TARGETVARIANT} /usr/bin/easy-add
RUN chmod +x /usr/bin/easy-add;

ARG RCON_CLI_VERSION=1.6.9
RUN easy-add --var os=${TARGETOS} --var arch=${TARGETARCH}${TARGETVARIANT} \
  --var version=${RCON_CLI_VERSION} --var app=rcon-cli --file {{.app}} \
  --from ${GITHUB_BASEURL}/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_{{.os}}_{{.arch}}.tar.gz ;

# Verify installation
RUN rcon-cli --help;

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
