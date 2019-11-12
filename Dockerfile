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
	dotnet-sdk-2.1 dotnet-sdk-2.2 dotnet-sdk-3.0 \
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

RUN mkdir -p /scisharp/kernel-spec \
&& cd /scisharp/kernel-spec \
&& wget https://raw.githubusercontent.com/SciSharp/ICSharpCore/master/kernel-spec/kernel-docker.json \
&& mv kernel-docker.json kernel.json \
&& wget https://raw.githubusercontent.com/SciSharp/ICSharpCore/master/kernel-spec/logo-32x32.png \
&& wget https://raw.githubusercontent.com/SciSharp/ICSharpCore/master/kernel-spec/logo-64x64.png \
&& echo '#r "nuget: TensorFlow.NET, 0.10.10"\n#r "nuget: PlotNET, 0.1.6"' > /scisharp/refs.txt \
&& jupyter kernelspec install /scisharp/kernel-spec --name=csharpcore

# Install ICSharpCore libraries
RUN mkdir -p /scisharp/lib \
&& cd /scisharp/lib \
&& wget https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-cpu-linux-x86_64-1.14.0.tar.gz \
&& tar -C /usr/local -xzf libtensorflow-cpu-linux-x86_64-1.14.0.tar.gz \
&& rm libtensorflow-cpu-linux-x86_64-1.14.0.tar.gz \
&& ldconfig

RUN chown -R ${NB_UID} ${HOME}

USER jovyan

ENV PATH="${PATH}:${HOME}/.dotnet/tools"

# Install Microsoft.DotNet.Interactive
RUN dotnet tool install -g dotnet-try \
&& dotnet try jupyter install

# Install Microsoft ML .NET CLI
RUN dotnet tool install -g mlnet

# Install ICSharpCore
RUN dotnet tool install -g ICSharpCore 

ADD notebooks ${HOME}/Notebooks

USER root
RUN chown -R ${NB_UID} ${HOME}/Notebooks
USER jovyan

# Set root to Notebooks
WORKDIR ${HOME}/Notebooks
