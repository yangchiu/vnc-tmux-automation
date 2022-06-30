FROM selenium/base:4.3.0-20220628
LABEL authors=SeleniumHQ

USER root

#==============
# Xvfb
#==============
RUN apt-get update -qqy \
  && apt-get -qqy install \
    xvfb \
    pulseaudio \
    tmux \
    pip \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#==============================
# Locale and encoding settings
#==============================
ENV LANG_WHICH en
ENV LANG_WHERE US
ENV ENCODING UTF-8
ENV LANGUAGE ${LANG_WHICH}_${LANG_WHERE}.${ENCODING}
ENV LANG ${LANGUAGE}
# Layer size: small: ~9 MB
# Layer size: small: ~9 MB MB (with --no-install-recommends)
RUN apt-get -qqy update \
  && apt-get -qqy --no-install-recommends install \
    language-pack-en \
    tzdata \
    locales \
  && locale-gen ${LANGUAGE} \
  && dpkg-reconfigure --frontend noninteractive locales \
  && apt-get -qyy autoremove \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get -qyy clean

#=====
# VNC
#=====
RUN apt-get update -qqy \
  && apt-get -qqy install \
  x11vnc \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#=========
# fluxbox
# A fast, lightweight and responsive window manager
#=========
RUN apt-get update -qqy \
  && apt-get -qqy install \
    fluxbox \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#================
# Font libraries
#================
# libfontconfig            ~1 MB
# libfreetype6             ~1 MB
# xfonts-cyrillic          ~2 MB
# xfonts-scalable          ~2 MB
# fonts-liberation         ~3 MB
# fonts-ipafont-gothic     ~13 MB
# fonts-wqy-zenhei         ~17 MB
# fonts-tlwg-loma-otf      ~300 KB
# ttf-ubuntu-font-family   ~5 MB
#   Ubuntu Font Family, sans-serif typeface hinted for clarity
# Removed packages:
# xfonts-100dpi            ~6 MB
# xfonts-75dpi             ~6 MB
# fonts-noto-color-emoji   ~10 MB
# Regarding fonts-liberation see:
#  https://github.com/SeleniumHQ/docker-selenium/issues/383#issuecomment-278367069
# Layer size: small: 50.3 MB (with --no-install-recommends)
# Layer size: small: 50.3 MB
RUN apt-get -qqy update \
  && apt-get -qqy --no-install-recommends install \
    libfontconfig \
    libfreetype6 \
    xfonts-cyrillic \
    xfonts-scalable \
    fonts-liberation \
    fonts-ipafont-gothic \
    fonts-wqy-zenhei \
    fonts-tlwg-loma-otf \
    ttf-ubuntu-font-family \
    fonts-noto-color-emoji \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get -qyy clean

########################################
# noVNC exposes VNC through a web page #
########################################
# Download https://github.com/novnc/noVNC dated 2021-03-30 commit 84f102d6a9ffaf3972693d59bad5c6fddb6d7fb0
# Download https://github.com/novnc/websockify dated 2021-03-22 commit c5d365dd1dbfee89881f1c1c02a2ac64838d645f
ENV NOVNC_SHA="84f102d6a9ffaf3972693d59bad5c6fddb6d7fb0" \
    WEBSOCKIFY_SHA="c5d365dd1dbfee89881f1c1c02a2ac64838d645f"
RUN  wget -nv -O noVNC.zip \
       "https://github.com/novnc/noVNC/archive/${NOVNC_SHA}.zip" \
  && unzip -x noVNC.zip \
  && mv noVNC-${NOVNC_SHA} /opt/bin/noVNC \
  && cp /opt/bin/noVNC/vnc.html /opt/bin/noVNC/index.html \
  && rm noVNC.zip \
  && wget -nv -O websockify.zip \
      "https://github.com/novnc/websockify/archive/${WEBSOCKIFY_SHA}.zip" \
  && unzip -x websockify.zip \
  && rm websockify.zip \
  && rm -rf websockify-${WEBSOCKIFY_SHA}/tests \
  && mv websockify-${WEBSOCKIFY_SHA} /opt/bin/noVNC/utils/websockify

#=========================================================================================================================================
# Run this command for executable file permissions for /dev/shm when this is a "child" container running in Docker Desktop and WSL2 distro
#=========================================================================================================================================
RUN chmod +x /dev/shm

#===================================================
# Run the following commands as non-privileged user
#===================================================

USER 1200

#==============================
# Scripts to run Selenium Node and XVFB
#==============================
COPY start-xvfb.sh \
      /opt/bin/

#==============================
# Generating the VNC password as seluser
# So the service can be started with seluser
#==============================

RUN mkdir -p ${HOME}/.vnc \
  && x11vnc -storepasswd secret ${HOME}/.vnc/passwd

#==========
# Relaxing permissions for OpenShift and other non-sudo environments
#==========
RUN sudo chmod -R 777 ${HOME} \
  && sudo chgrp -R 0 ${HOME} \
  && sudo chmod -R g=u ${HOME}

#==============================
# Scripts to run fluxbox, x11vnc and noVNC
#==============================
COPY start-vnc.sh \
      start-novnc.sh \
      /opt/bin/

#============================
# Some configuration options
#============================
ENV SE_SCREEN_WIDTH 1360
ENV SE_SCREEN_HEIGHT 1020
ENV SE_SCREEN_DEPTH 24
ENV SE_SCREEN_DPI 96
ENV SE_START_XVFB true
# Temporal fix for https://github.com/SeleniumHQ/docker-selenium/issues/1610
ENV START_XVFB true
ENV SE_START_NO_VNC true
ENV SE_NO_VNC_PORT 7900
ENV SE_VNC_PORT 5900
ENV DISPLAY :99.0
ENV DISPLAY_NUM 99
# Path to the Configfile
ENV GENERATE_CONFIG true
# Drain the Node after N sessions.
# A value higher than zero enables the feature
ENV SE_DRAIN_AFTER_SESSION_COUNT 0



#========================
# Selenium Configuration
#========================
# As integer, maps to "max-concurrent-sessions"
ENV SE_NODE_MAX_SESSIONS 1
# As integer, maps to "session-timeout" in seconds
ENV SE_NODE_SESSION_TIMEOUT 300
# As boolean, maps to "override-max-sessions"
ENV SE_NODE_OVERRIDE_MAX_SESSIONS false

# Following line fixes https://github.com/SeleniumHQ/docker-selenium/issues/87
ENV DBUS_SESSION_BUS_ADDRESS=/dev/null

# Creating base directory for Xvfb
RUN  sudo mkdir -p /tmp/.X11-unix && sudo chmod 1777 /tmp/.X11-unix

EXPOSE 5900

RUN sudo chmod -R 777 /opt/bin \
  && sudo chgrp -R 0 /opt/bin \
  && sudo chmod -R g=u /opt/bin

RUN sudo apt-get update && \
    sudo apt-get install -y apt-transport-https ca-certificates curl ssh && \
    sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list && \
    sudo apt-get update && \
    sudo apt-get install -y kubectl

RUN sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    sudo unzip awscliv2.zip && \
    sudo ./aws/install

#RUN sudo apt-get install -y dialog apt-utils openssh-server && \
#    sudo service start ssh
#RUN nohup bash -c "/opt/bin/start-xvfb.sh &" && sleep 5

#RUN nohup bash -c "/opt/bin/start-vnc.sh &" && sleep 5

#RUN nohup bash -c "/opt/bin/start-novnc.sh &" && sleep 5

COPY requirements.txt ${HOME}/requirements.txt

RUN pip install -r ${HOME}/requirements.txt

RUN export PATH="${HOME}/.local/bin:$PATH"

CMD nohup bash -c "/opt/bin/start-xvfb.sh &" && sleep 5 && nohup bash -c "/opt/bin/start-vnc.sh &" && sleep 5 && nohup bash -c "/opt/bin/start-novnc.sh &" && sleep 5 && DISAPLY=:99 xterm -sb -rightbar -geometry 118x33+1+1 -fa 'Monospace' -fs 14 -e /bin/bash -l -c "cd ~ && tmux new-session -s session -n window"