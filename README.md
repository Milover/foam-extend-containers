# OpenFOAM development setup

Files for setting up a containerized development environment for [foam-extend][fe]
along with the [solids4foam][s4f] project.
The default foam-extend version is 4.1, but it can be supplied at build time
through the `FOAM_VERSION` variable, e.g.:

```shell
$ docker build --build-arg FOAM_VERSION="4.0"
```

Official [OpenFOAM][of] container images are available [here][opencfd].

Requirements:

* [Docker][docker]

**Note**: ParaView and Python dependent stuff is not built (e.g. pyFoam, swak4foam).

### TODO

- [ ] add short example of usage
- [ ] add link to ready-made image

## License

[MIT License][lic]

[of]: https://www.openfoam.com
[opencfd]: https://hub.docker.com/u/opencfd
[fe]: https://sourceforge.net/projects/foam-extend/
[s4f]: https://bitbucket.org/philip_cardiff/solids4foam-release/src/master/
[docker]: https://www.docker.com
[lic]: LICENSE
