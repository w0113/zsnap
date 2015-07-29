
# ZSnap

## About

ZSnap is a simple snapshot tool to create periodic snapshots automatically for ZFS on Linux.


## Usage

ZSnap is able to create new snapshots on a set of ZFS volumes and to delete old snapshots, which are older than a user specified period of time. ZSnap is written as a commandline tool. After installation it should be possible to execute the command `zsnap -h` to get a help summary: 

    Usage: zsnap [OPTION]... [VOLUME]...
    Automatically create and destroy snapshots for ZFS VOLUME(s).

    The options -M, -H, -d, -w or -m are used to specify which snapshots should
    be destroyed. It is possible to combine those options, e. g. '-w 2 -H 12'
    would delete all snapshots which are older than two weeks and twelve hours. If
    none of those options are used, no snapshot will be destroyed. Furthermore
    only snapshots created by this script will be deleted, all other snapshots
    remain untouched.

    All choosen operations are only applied to the specified volumes. Those
    volumes must be ZFS volumes and if no volumes are specified, the operation is
    done on ALL available volumes.

    Note: This script is intended to be used in a cronjob. E. g. to make a snapshot
    every full hour and keep the snapshots of the last two weeks, add this line to
    your '/etc/crontab' file:
        0 * * * *  root  zsnap -c -w 2

    Options:

        -c, --create                     Create a snapshot for all specified VOLUME(s).
        -M, --minutes [NUMBER]           Destroy every snapshot which is older than NUMBER of minutes,
                                         for all specified VOLUME(s).
        -H, --hours [NUMBER]             Destroy every snapshot which is older than NUMBER of hours,
                                         for all specified VOLUME(s).
        -d, --days [NUMBER]              Destroy every snapshot which is older than NUMBER of days,
                                         for all specified VOLUME(s).
        -w, --weeks [NUMBER]             Destroy every snapshot which is older than NUMBER of weeks,
                                         for all specified VOLUME(s).
        -m, --months [NUMBER]            Destroy every snapshot which is older than NUMBER of months,
                                         for all specified VOLUME(s).
        -h, --help                       Show this message.
        -v                               Be verbose.

    Examples:

     - zsnap -c
       Create a new snapshot for all volumes.

     - zsnap -c -w 8 tank
       Create a new snapshot and destroy all snapshots which are older than eight
       weeks, for volume 'tank'.

     - zsnap -m 1 -w 2
       Destroy all snapshots which are older than one month and two weeks.


## Installation

ZSnap is written in Ruby and therefore needs a Ruby interepreter to run. To install a ruby interpreter on a Debian based system, this is usually done by issuing the following command as root:

    apt-get install ruby

To run ZSnap only the file 'zsnap.rb' from the foulder 'src' is needed, but it is recommended to clone the whole project and create a link to the 'zsnap.rb' script, e. g. type as root:

    git clone https://github.com/w0113/zsnap.git /usr/local/src/
    ln -s /usr/local/src/zsnap/src/zsnap.rb /usr/local/sbin/zsnap

Afterwards it should be possible as user root to execute ZSnap by simple typing `zsnap`. To get further help use the `zsnap -h` command.


## License

ZSnap is released under the [MIT License](https://tldrlegal.com/license/mit-license).

