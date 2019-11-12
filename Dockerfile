FROM jupyter/scipy-notebook:latest
LABEL maintainer="info@bytesmith.de"

# Environment variables and args
ENV USER jovyan \
    NB_UID 1000 \
    HOME /home/jovyan

WORKDIR ${HOME}

USER root

RUN apt-get update \
&& apt-get install -y --no-install-recommends \
    curl wget \
    libc6 libgcc1 libgssapi-krb5-2 libicu60 libssl1.1 libstdc++6 zlib1g \
&& rm -rf /tmp/* \
    && apt-get autoremove -y \
    && apt-get autoclean -y \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
&& apt-get install -y --no-install-recommends \
    apt-transport-https \
&& cd /tmp \
&& wget http://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb \
&& dpkg -i packages-microsoft-prod.deb \
&& apt-get update \
&& apt-get install -y --no-install-recommends \
	dotnet-sdk-2.1 dotnet-sdk-3.0 \
&& rm -rf /tmp/* \
    && apt-get autoremove -y \
    && apt-get autoclean -y \
    && rm -rf /var/lib/apt/lists/*

# Enable detection of running in a container
ENV DOTNET_RUNNING_IN_CONTAINER=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Opt-out of .NET Core telemetry
    DOTNET_CLI_TELEMETRY_OPTOUT=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip

RUN chown -R ${NB_UID} ${HOME}
USER jovyan

ENV PATH="${PATH}:${HOME}/.dotnet/tools"

# Install Microsoft.DotNet.Interactive
RUN dotnet tool install -g dotnet-try \
&& dotnet try jupyter install

RUN dotnet tool install -g mlnet

ADD notebooks ${HOME}/Notebooks

# Set root to Notebooks
WORKDIR ${HOME}/Notebooks
