# docker-aria2

This repo is a combination of [AriaNg](https://github.com/mayswind/AriaNg) and [aria2](https://github.com/aria2/aria2), target version can be found in [Dockerfile](./Dockerfile) ENV arg `UI_VERSION`, `ARIA2_VERSION`. Migrated from my old supervisor setting for fast deploy and add multi-stage build for custom compile aria2c.

> ⚠️this custom compiled aria2c has released `max-connection-per-server` up to __4096__(default is 16), please USE AT YOUR OWN RISK. IOW you can fork this or download this repo to build your own ARIA2

## How to Use

### UnRaid OS quick deploy

if you want to deploy on your UnRaid OS, I have already provide out of box solution, [UnRaid-aria2-template](./UnRaid-aria2-template.xml) in project. Importing template with approach:

1. no need to create docker template repository temporary, so use second one...

1. Download and Copy the [UnRaid-aria2-template](./UnRaid-aria2-template.xml) to the path - `/boot/config/plugins/dockerMan/templates-user` of USB Flash drive.

### Common deploy

The simplest way to use it is pulling the image from dockerhub and RUN it with my default aria configuration. default rpc secret token is `aadd6df9284fa9becd2eb3b51818c5c2`
> bt-tracker auto retrieving data from [This Repo](https://github.com/ngosang/trackerslist) with [trackers_all.txt](https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt) when container is starting, so you can update tracker with restart container way. Also can update from ui bt setting segment.

eg.

```sh
docker run -d --name docker-aria2 -p 8800:80/tcp -p 8880:8080/tcp dogbutcat/docker-aria2
```

OR

you can also override all aria2c apis to command follow by repo

eg.

```sh
docker run -d --name docker-aria2 -p 8800:80/tcp -p 8880:8081/tcp dogbutcat/docker-aria2 \
        --enable-rpc --input-file=.aria2/aria2.session --conf-path=.aria2/aria2.conf --rpc-secret=[new token] --rpc-listen-port=8081
```

you can find all api [here](https://aria2.github.io/manual/en/html/aria2c.html) and also can mirror the container path `/opt/aria2/config` to your local path.

AND

by default, download directory is `/data` which you can set in [aria2.conf](./config/aria2.conf) and work as a mount point. If not provided, docker will create a anyomous volume which you can find with `docker volume ls`, or you can add bind path/create volume when start the docker:

eg.

```sh
docker run -d --name docker-aria2 -v replacethiswithyourpathorvolumename:/data -p 8800:80/tcp -p 8880:8081/tcp dogbutcat/docker-aria2
```

MORE

Integrated with nginx, so you can do more with it after bind volume `/etc/nginx/config.d` or whatever you like.

## Caveats

- if you want add some custom tracker, please add bt-tracker in config file.

- ipv6 only support docker on linux host. see [link](https://docs.docker.com/config/daemon/ipv6/)
  - if you want take use of ipv6, so disabled in default, get more info [here](https://docs.docker.com/v17.09/engine/userguide/networking/default_network/ipv6/), if you need it, you can use your own command in start option.

- building with `libgnutls` is not available under static mode see [link](https://gitlab.com/gnutls/gnutls/issues/203)
  - provided 2 type of setting configuration, static and dynamic, default in static way.
  - need `strip` to remove debug symbol
