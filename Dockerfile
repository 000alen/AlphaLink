FROM nvidia/cuda:11.3.1-cudnn8-runtime-ubuntu18.04

# OK
RUN apt-key del 7fa2af80
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub

RUN apt-get update && apt-get install -y wget libxml2 cuda-minimal-build-11-3 libcusparse-dev-11-3 libcublas-dev-11-3 libcusolver-dev-11-3 git
RUN wget -P /tmp \
    "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" \
    && bash /tmp/Miniconda3-latest-Linux-x86_64.sh -b -p /opt/conda \
    && rm /tmp/Miniconda3-latest-Linux-x86_64.sh
ENV PATH /opt/conda/bin:$PATH

COPY environment.yml /opt/openfold/environment.yml

## installing into the base environment since the docker container wont do anything other than run openfold
RUN conda install -c conda-forge mamba
RUN mamba env update -n base --file /opt/openfold/environment.yml 

# ? NOTE: This is not strictly necessary, but it would potentially reduce the size of the docker image. However, currently this breaks the docker image. 
# RUN mamba clean --all

COPY openfold /opt/openfold/openfold
COPY scripts /opt/openfold/scripts
COPY run_pretrained_openfold.py /opt/openfold/run_pretrained_openfold.py
COPY train_openfold.py /opt/openfold/train_openfold.py
COPY setup.py /opt/openfold/setup.py

# ? NOTE: This is not necessary (and would not work) for two reasons:
# ? 1. The patch was offically merged into openmm
# ? 2. Since it was already merged, the patch is no longer compatible with the current version of openmm and throws an error
# COPY lib/openmm.patch /opt/openfold/lib/openmm.patch

RUN wget -q -P /opt/openfold/openfold/resources \
    https://git.scicore.unibas.ch/schwede/openstructure/-/raw/7102c63615b64735c4941278d92b554ec94415f8/modules/mol/alg/src/stereo_chemical_props.txt

# ? NOTE: This is not necessary (and would not work) for two reasons:
# ? 1. The patch was offically merged into openmm
# ? 2. Since it was already merged, the patch is no longer compatible with the current version of openmm and throws an error
# RUN patch -p0 -d /opt/conda/lib/python3.7/site-packages/ < /opt/openfold/lib/openmm.patch

WORKDIR /opt/openfold
RUN python3 setup.py install

COPY preprocessing_distributions.py /opt/openfold/
COPY predict_with_crosslinks.py /opt/openfold/
COPY contacts_to_distograms.py /opt/openfold/