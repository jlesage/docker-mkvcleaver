# Docker container for MKVCleaver
[![Docker Image](https://images.microbadger.com/badges/image/jlesage/mkvcleaver.svg)](http://microbadger.com/#/images/jlesage/mkvcleaver) [![Build Status](https://travis-ci.org/jlesage/docker-mkvcleaver.svg?branch=master)](https://travis-ci.org/jlesage/docker-mkvcleaver) [![GitHub Release](https://img.shields.io/github/release/jlesage/docker-mkvcleaver.svg)](https://github.com/jlesage/docker-mkvcleaver/releases/latest) [![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://paypal.me/JocelynLeSage/0usd)

This is a Docker container for [MKVCleaver](https://blogs.sapib.ca/apps/mkvcleaver/).

The GUI of the application is accessed through a modern web browser (no installation or configuration needed on client side) or via any VNC client.

---

[![MKVCleaver logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/mkvcleaver-icon.png&w=200)](https://blogs.sapib.ca/apps/mkvcleaver/)[![MKVCleaver](https://dummyimage.com/400x110/ffffff/575757&text=MKVCleaver)](https://blogs.sapib.ca/apps/mkvcleaver/)

MKVCleaver is a tool for batch extraction of data from MKV files

---

## Quick Start

**NOTE**: The Docker command provided in this quick start is given as an example
and parameters should be adjusted to your need.

Launch the MKVCleaver docker container with the following command:
```
docker run -d \
    --name=mkvcleaver \
    -p 5800:5800 \
    -v /docker/appdata/mkvcleaver:/config:rw \
    -v $HOME:/storage:rw \
    jlesage/mkvcleaver
```

Where:
  - `/docker/appdata/mkvcleaver`: This is where the application stores its configuration, log and any files needing persistency.
  - `$HOME`: This location contains files from your host that need to be accessible by the application.

Browse to `http://your-host-ip:5800` to access the MKVCleaver GUI.
Files from the host appear under the `/storage` folder in the container.

## Documentation

Full documentation is available at https://github.com/jlesage/docker-mkvcleaver.

## Support or Contact

Having troubles with the container or have questions?  Please
[create a new issue].

For other great Dockerized applications, see https://jlesage.github.io/docker-apps.

[create a new issue]: https://github.com/jlesage/docker-mkvcleaver/issues
