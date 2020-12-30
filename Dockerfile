FROM mcr.microsoft.com/powershell:latest

RUN \
    TZ=Europe/Stockholm \
    && ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone \
    && dpkg-reconfigure --frontend noninteractive tzdata

# get script from github
 RUN \
    WEATHERBOX_VERSION=0.0.13 \
    && mkdir -p ~/FetchGarminData \
    && cd ~/FetchGarminData \
    && wget https://github.com/matswi/FetchGarminData/raw/master/FetchGarminData.ps1 \
    && && mkdir -p ~/weatherbox/GarminConnect \
    && cd ~/weatherbox/GarminConnect \
    && wget https://raw.githubusercontent.com/matswi/GarminConnect/main/GarminConnect/GarminConnect.psd1 \
    && wget https://github.com/matswi/GarminConnect/raw/main/GarminConnect/GarminConnect.psm1

# Use PowerShell as the default shell
# Use array to avoid Docker prepending /bin/sh -c
ENTRYPOINT [ "pwsh" ]
#CMD [ "/root/FetchGarminData/FetchGarminData.ps1" ]