# Copyright (c) Microsoft Corporation. 
# Licensed under the MIT License.

FROM arm32v7/ubuntu:bionic

ENV PS_VERSION=7.1.0
ENV PS_PACKAGE=powershell-${PS_VERSION}-linux-arm32.tar.gz
ENV PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}

RUN \
  apt-get update \
  && apt-get install --no-install-recommends ca-certificates libunwind8 libssl1.0 libicu60 wget unzip --yes \
  && wget https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE} \
  && mkdir ~/powershell \
  && tar -xvf ./${PS_PACKAGE} -C ~/powershell \
  && ln -s /root/powershell/pwsh /usr/bin/pwsh \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# RUN \
#    TZ=Europe/Stockholm \
#    && ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone \
#    && dpkg-reconfigure --frontend noninteractive tzdata

# get script from github
 RUN \
    FETCHGARMINDATA_VERSION=0.0.0.11 \
    && mkdir -p /root/FetchGarminData \
    && cd /root/FetchGarminData \
    && wget https://github.com/matswi/FetchGarminData/raw/master/FetchGarminData.ps1 \
    && mkdir -p /root/FetchGarminData/GarminConnect \
    && cd /root/FetchGarminData/GarminConnect \
    && wget https://raw.githubusercontent.com/matswi/GarminConnect/main/GarminConnect/GarminConnect.psd1 \
    && wget https://github.com/matswi/GarminConnect/raw/main/GarminConnect/GarminConnect.psm1

# Use PowerShell as the default shell
# Use array to avoid Docker prepending /bin/sh -c
ENTRYPOINT [ "pwsh" ]
#CMD [ "/root/FetchGarminData/FetchGarminData.ps1" ]