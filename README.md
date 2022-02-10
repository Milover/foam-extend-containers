# Containers for foam-extend and related projects

Files for setting up base container images for [foam-extend][fe] and the
[solids4foam][s4f] project.
The default foam-extend version is 4.1, but it can be changed in the Makefile
by changing the `FOAM_VERSION` variable.

__Notes:__
* most third party components aren't built/included (e.g. pyFoam, metis)
* build tools aren't included in the base images
* master branch tips are used for building

Prebuilt images are available through the [Docker hub][docker-hub]:
* [foam-extend][fe-hub]
* [solids4foam][s4f-hub]

## Build

Only [Docker][docker] is necessary for building, since all sources are pulled
during the build.

The images can be built by running:

```shell
$ make foam-extend
$ make solids4foam
```

Depending on your Docker setup, you might have to prepend `sudo` to the make
commands.

## License

[MIT License][lic]

[of]: https://www.openfoam.com
[opencfd]: https://hub.docker.com/u/opencfd
[fe]: https://sourceforge.net/projects/foam-extend/
[s4f]: https://bitbucket.org/philip_cardiff/solids4foam-release/src/master/
[docker]: https://www.docker.com
[lic]: LICENSE
[docker-hub]: https://hub.docker.com
[fe-hub]: https://hub.docker.com/r/capsisescape/foam-extend
[s4f-hub]: https://hub.docker.com/r/capsisescape/solids4foam
