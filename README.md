Usage
-----

On Ubuntu, install the following packages,

```
sudo aptitude install libswitch-perl libdatetime-perl \
   libtext-glob-perl libdata-hexdumper-perl \
   libdata-printer-perl -y
```

On Fedora, install the following packages,

```
sudo dnf install perl-Data-Printer perl-Switch \
   perl-DateTime perl-Compress-Raw-Lzma \
   perl-Digest-CRC
```

Get the "hash" to crack,

```
./inno2john.pl samples/Output.old/setup.exe > hash
```

Give ``hash`` to JtR.

It seems that, ``samples/hot-hash`` is the hottest thing on the internet today!
