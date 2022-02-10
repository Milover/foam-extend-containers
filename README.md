# Containers for foam-extend and related projects

Files for setting up base container images for [foam-extend][fe] and the
[solids4foam][s4f] project.
The default foam-extend version is 4.1, but it can be changed in the Makefile
by chaning the `FOAM_VERSION` variable.

Requirements:

* [Docker][docker]

__Notes:__
* most third party components aren't built/included (e.g. pyFoam, metis)
* build tools aren't included in the base images
* master branch tips are used for building

Prebuilt images are available through the [Docker hub][docker-hub]:
* [foam-extend][fe-hub]
* [solids4foam][s4f-hub]

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
