FROM jupyter/minimal-notebook
ENV CONDA_OVERRIDE_CUDA=11.6
USER root
# Needed for graphviz stuff to work
RUN apt-get -qq update --yes && apt-get -qq install --yes graphviz curl ffmpeg libsm6 libxext6 && \
    apt-get -qq clean && rm -rf /var/lib/apt/lists/* && mkdir /content && chown jovyan:users /content
USER ${NB_UID}
RUN git clone --depth 1 https://github.com/fastai/fastbook
# Use sed to fix bugs until fastai/fastbook PR #504 and #505 are merged
# Also change environment name to 'base' since we don't need a seperate env in a docker container
RUN cat fastbook/environment.yml | sed 's/file://g' | sed 's/fastbook/base/g' | sed 's/torchvision/torchvision=0.11.3/g' > fastbook/environment.yml.new && \
    mv fastbook/environment.yml fastbook/environment.yml.old && \
    mv fastbook/environment.yml.new fastbook/environment.yml
RUN mamba env update -q -f fastbook/environment.yml
# default to Darkmode. Comment out if you don't want this
COPY overrides.json /opt/conda/share/jupyter/lab/settings/

RUN mamba update -y libstdcxx-ng && mamba install -yq jupyter_http_over_ws librosa opencv && jupyter serverextension enable --py jupyter_http_over_ws

# Configure container startup
ENTRYPOINT ["tini", "-g", "--"]
CMD ["start.sh", "jupyter", "notebook", "--no-browser", "--no-mathjax", "--NotebookApp.allow_origin='https://colab.research.google.com'", "--port=8889", "--NotebookApp.port_retries=0"]
