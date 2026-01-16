# juju-db-oci

## To build a specific image

Find the name of the image in images.yaml

```sh
IMAGES=juju-db-4.4 make build
```

## To push a specific image

Find the name of the image in images.yaml

```sh
IMAGES=juju-db-4.4 make push
```

## To build all images

```sh
make build
```

## To push all images

```sh
make push
```
