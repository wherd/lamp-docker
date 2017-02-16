# lamp-docker

LAMP development stack used to get started on web projects.

## Installed software

git, curl, pwgen, wget, apache2, myqsl, php, memcached & composer

## Build docker image

```
sudo docker build -t wherd/lamp-docker .
```

## Run
```
sudo docker run -d -p 80:80 --name {PROJECT__NAME} -v {PROJECT__PATH}:/var/www/localhost wherd/lamp-docker
```

## Cleanup
```
sudo docker rm -f {PROJECT__NAME}
```
