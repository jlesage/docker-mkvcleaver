# Docker container for MKVCleaver
[![Release](https://img.shields.io/github/release/jlesage/docker-mkvcleaver.svg?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-mkvcleaver/releases/latest)
[![Docker Image Size](https://img.shields.io/docker/image-size/jlesage/mkvcleaver/latest?logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/mkvcleaver/tags)
[![Docker Pulls](https://img.shields.io/docker/pulls/jlesage/mkvcleaver?label=Pulls&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/mkvcleaver)
[![Docker Stars](https://img.shields.io/docker/stars/jlesage/mkvcleaver?label=Stars&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/mkvcleaver)
[![Build Status](https://img.shields.io/github/actions/workflow/status/jlesage/docker-mkvcleaver/build-image.yml?logo=github&branch=master&style=for-the-badge)](https://github.com/jlesage/docker-mkvcleaver/actions/workflows/build-image.yml)
[![Source](https://img.shields.io/badge/Source-GitHub-blue?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-mkvcleaver)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg?style=for-the-badge)](https://paypal.me/JocelynLeSage)

This is a Docker container for [MKVCleaver](https://blogs.sapib.ca/apps/mkvcleaver/).

The graphical user interface (GUI) of the application can be accessed through a
modern web browser, requiring no installation or configuration on the client

---

[![MKVCleaver logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/mkvcleaver-icon.png&w=110)](https://blogs.sapib.ca/apps/mkvcleaver/)[![MKVCleaver](https://images.placeholders.dev/?width=320&height=110&fontFamily=monospace&fontWeight=400&fontSize=52&text=MKVCleaver&bgColor=rgba(0,0,0,0.0)&textColor=rgba(121,121,121,1))](https://blogs.sapib.ca/apps/mkvcleaver/)

MKVcleaver is a GUI (Graphical User Interface) for mkvtoolnix, designed to extract
data from MKV files. It can be used in a batch mode (loading and extracting data
from many files) as well as single file mode. It has a simple GUI interface, but a
lot of functionality.

---

## Quick Start

**NOTE**:
    The Docker command provided in this quick start is an example, and parameters
    should be adjusted to suit your needs.

Launch the MKVCleaver docker container with the following command:
```shell
docker run -d \
    --name=mkvcleaver \
    -p 5800:5800 \
    -v /docker/appdata/mkvcleaver:/config:rw \
    -v /home/user:/storage:rw \
    jlesage/mkvcleaver
```

Where:

  - `/docker/appdata/mkvcleaver`: Stores the application's configuration, state, logs, and any files requiring persistency.
  - `/home/user`: Contains files from the host that need to be accessible to the application.

Access the MKVCleaver GUI by browsing to `http://your-host-ip:5800`.
Files from the host appear under the `/storage` folder in the container.

## Documentation

Full documentation is available at https://github.com/jlesage/docker-mkvcleaver.

## Support or Contact

Having troubles with the container or have questions? Please
[create a new issue](https://github.com/jlesage/docker-mkvcleaver/issues).

For other Dockerized applications, visit https://jlesage.github.io/docker-apps.
