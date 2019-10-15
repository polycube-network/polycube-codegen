polycube code generation tools
******************************

This repository includes `pyang-swagger <https://github.com/polycube-network/pyang-swagger>`_ and `swagger-codegen <https://github.com/polycube-network/swagger-codegen>`_, two tools that are used to generate a polycube stub from a YANG datamodel.

If you only want to generate a stub from a yang datamodel please go directly to `docker`_.

Installation
============

The easiest way to install the dependencies and the tools is to use the ``install.sh`` script.
If you want to install those by hands please refer to each repository to get further details.

::

    cd polycube-tools
    git submodule update --init
    ./install.sh

Usage
=====

``polycube-codegen`` expects the ``POLYCUBE_BASE_DATAMODELS_FOLDER`` to be set to the folder were the base datamodels of polycube are located.
If you have installed polycube in the standard location and everything is ok you could omit that parameter that defaults to ``/usr/local/include/polycube/datamodel-common/``.

::

    $ polycube-codegen [-h] [-i input_yang] [-o output_folder] [-s output_swagger_file] [-l client_language]
    Polycube code generator that translates a YANG file into an polycube C++ service stub

    where:
        -h  show this help text
        -i  path to the input YANG file
        -o  path to the destination folder where the service stub will be placed
        -s  path to the destination swagger file (optional)
        -l  language used to generate service's client library (optional)"

Client stub for Polycube services
^^^^^^

Each Polycube service uses a specific convention for generate the REST APIs that are used by external players to interact with the service itself. 
In order to interact with those service, users can use the ``polycubectl`` CLI tool or creates their own client programs that communicates with a given service.
To simplify the creation of those programs, ``polycube-codegen`` supports the generation of client stubs in different programming languages such as ``golang``, ``java``, ``python`` (full list available `here <https://github.com/swagger-api/swagger-codegen#overview>`_ under the ``swagger-codegen`` project).

To do this, we can directly use the provided ``polycube-codegen`` script adding the ``-l`` option with the name of the language you want to use.
For instance, in order to generate the client stub for the ``pcn-simplebridge`` service, the command that you can use is the following:

::

    polycube-codegen -i pcn-simplebridge.yang -o output_dir -l go

In its final processing step, polycube-codegen relies on the online service https://generator.swagger.io/api/gen/clients generator to create the code stub; hence this requires Internet connectivity.

Alternatively, if you do not want to install the ``polycube-codegen`` tool, you can use the same syntax in the provided Docker image.

Docker
^^^^^^

We provide the ``polycubenetwork/polycube-codegen`` docker image with the tools installed.
The entry point of the image is ``polycube-codegen``, so the usage is almost the same as above.
In this case you should provide a volume in ``/polycube-base-datamodel`` with the polycube base datamodels.

The following is a full command line example, the ``--user `id -u``` guarantees that the generated files have the permissions set to the current user.

::

    export POLYCUBE_BASEMODELS=<path to base models usually /usr/local/include/polycube/datamodel-common/>
    docker pull polycubenetwork/polycube-codegen
    docker run -it --user `id -u` \
      -v $POLYCUBE_BASEMODELS:/polycube-base-datamodels \
      -v <input yang>:/input \
      -v <output folder in host>:/output \
      polycubenetwork/polycube-codegen \
      -i /input/<yang datamodel> \
      -o /output/<output folder>

