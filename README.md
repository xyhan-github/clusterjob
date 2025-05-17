# ClusterJob (MODIFIED)

_This is a modified version of H. Monajemi's original clusterjob maintained by X.Y. Han. The original instructions "clusterjob.org" etc are nolonger accessible online. But you can still see them on Wayback Machine to get a sense of how to install it._

Clusterjob, hereafter CJ, is an experiment management system (EMS) for data science. CJ is 
written mainly in perl and allows submiting computational jobs to clusters in a hassle-free and reproducible manner.
CJ produces 'reporoducible' computational packages for academic publications at no-cost. CJ project started in 2013 at Stanford University by Hatef Monajemi and his PhD advisor David L. Donoho with the goal of encouraging  more efficient and reproducible research paradigm. 
CJ is currently under active development. Current implementation allows submission of MATLAB,Python and R jobs. 
The code for R works partially for serial jobs only.


# key contributors:

1. Hatef Monajemi
2. Bekk Blando 
3. David Donoho
4. Vardan Papyan
5. X.Y. Han


# How to cite ClusterJob

```
@article{clusterjob,
Author = {H.~Monajemi and D.~L.~Donoho},
Month = March,
Url= {https://github.com/monajemi/clusterjob},
Title = {ClusterJob: An automated system for painless and reproducible massive computational experiments},
Year = 2015}


@article{MMCEP17,
title = {Making massive computational experiments painless},
author = {H.~Monajemi  and D.~L.~Donoho and V.~Stodden},
journal={Big Data (Big Data), 2016 IEEE International Conference on},
year={2017},
month={February},
}



@article{Monajemi19,
title = {Ambitious data science can be painless},
author = {H.~Monajemi and R.~Murri and E.~Yonas and P.~Liang and V.~Stodden and D.L.~Donoho},
note={arXiv:1901.08705},
year={2019},
}
```



Copyright 2015 Hatef Monajemi (monajemi@stanford.edu)

## Cluster configuration

Each cluster is described in the `ssh_config` file.  In addition to the existing
`Repo` entry that controls where run data is stored, you can optionally specify
`CondaRepo` to choose the directory where CJ installs Miniconda on that machine.
If omitted, `CondaRepo` defaults to the same path as `Repo`.


