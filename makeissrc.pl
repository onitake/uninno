#!/usr/bin/perl

use strict;
use warnings;

my $git = 'git';
my $unzip = 'unzip';
my $wget = 'wget';
my $srcdir = 'innosetup';
my $giturl = 'https://github.com/jrsoftware/issrc.git';
my $firstcommit = '238b7749629c219c25716a5f04a66fb9dfa5feb2';
my $branch = 'old';
my @sources = qw(
http://www.jrsoftware.org/download.php/issrc-1.2.16.zip
http://www.jrsoftware.org/download.php/issrc-1.3.26.zip
http://www.jrsoftware.org/download.php/issrc-2.0.19.zip
http://www.jrsoftware.org/download.php/issrc-3.0.7.zip
http://files.jrsoftware.org/is/4/issrc-4.0.8.zip
http://files.jrsoftware.org/is/4/issrc-4.0.9.zip
http://files.jrsoftware.org/is/4/issrc-4.0.10.zip
http://files.jrsoftware.org/is/4/issrc-4.0.11.zip
http://files.jrsoftware.org/is/4/issrc-4.1.0.zip
http://files.jrsoftware.org/is/4/issrc-4.1.1.zip
http://files.jrsoftware.org/is/4/issrc-4.1.2.zip
http://files.jrsoftware.org/is/4/issrc-4.1.3.zip
http://files.jrsoftware.org/is/4/issrc-4.1.4.zip
http://files.jrsoftware.org/is/4/issrc-4.1.5.zip
http://files.jrsoftware.org/is/4/issrc-4.1.6.zip
http://files.jrsoftware.org/is/4/issrc-4.1.7.zip
http://files.jrsoftware.org/is/4/issrc-4.1.8.zip
http://files.jrsoftware.org/is/4/issrc-4.2.0.zip
http://files.jrsoftware.org/is/4/issrc-4.2.1.zip
http://files.jrsoftware.org/is/4/issrc-4.2.2.zip
http://files.jrsoftware.org/is/4/issrc-4.2.3.zip
http://files.jrsoftware.org/is/4/issrc-4.2.4.zip
http://files.jrsoftware.org/is/4/issrc-4.2.5.zip
http://files.jrsoftware.org/is/4/issrc-4.2.6.zip
http://files.jrsoftware.org/is/4/issrc-4.2.7.zip
http://files.jrsoftware.org/is/5/issrc-5.0.0-beta.zip
http://files.jrsoftware.org/is/5/issrc-5.0.1-beta.zip
http://files.jrsoftware.org/is/5/issrc-5.0.2-beta.zip
http://files.jrsoftware.org/is/5/issrc-5.0.3-beta.zip
http://files.jrsoftware.org/is/5/issrc-5.0.4-beta.zip
http://files.jrsoftware.org/is/5/issrc-5.0.5-beta.zip
http://files.jrsoftware.org/is/5/issrc-5.0.6.zip
http://files.jrsoftware.org/is/5/issrc-5.0.7.zip
http://files.jrsoftware.org/is/5/issrc-5.0.8.zip
http://files.jrsoftware.org/is/5/issrc-5.1.0-beta.zip
http://files.jrsoftware.org/is/5/issrc-5.1.1-beta.zip
http://files.jrsoftware.org/is/5/issrc-5.1.2-beta.zip
http://files.jrsoftware.org/is/5/issrc-5.1.3-beta.zip
http://files.jrsoftware.org/is/5/issrc-5.1.4.zip
http://files.jrsoftware.org/is/5/issrc-5.1.5.zip
http://files.jrsoftware.org/is/5/issrc-5.1.6.zip
http://files.jrsoftware.org/is/5/issrc-5.1.7.zip
http://files.jrsoftware.org/is/5/issrc-5.1.8.zip
http://files.jrsoftware.org/is/5/issrc-5.1.9.zip
http://files.jrsoftware.org/is/5/issrc-5.1.10.zip
http://files.jrsoftware.org/is/5/issrc-5.1.11.zip
http://files.jrsoftware.org/is/5/issrc-5.1.12.zip
http://files.jrsoftware.org/is/5/issrc-5.1.13.zip
http://files.jrsoftware.org/is/5/issrc-5.1.14.zip
http://files.jrsoftware.org/is/5/issrc-5.2.0.zip
http://files.jrsoftware.org/is/5/issrc-5.2.1.zip
http://files.jrsoftware.org/is/5/issrc-5.2.2.zip
http://files.jrsoftware.org/is/5/issrc-5.2.3.zip
http://files.jrsoftware.org/is/5/issrc-5.3.0-beta.zip
http://files.jrsoftware.org/is/5/issrc-5.3.1-beta.zip
http://files.jrsoftware.org/is/5/issrc-5.3.2-beta.zip
http://files.jrsoftware.org/is/5/issrc-5.3.3.zip
http://files.jrsoftware.org/is/5/issrc-5.3.4.zip
http://files.jrsoftware.org/is/5/issrc-5.3.5.zip
http://files.jrsoftware.org/is/5/issrc-5.3.6.zip
http://files.jrsoftware.org/is/5/issrc-5.3.7.zip
http://files.jrsoftware.org/is/5/issrc-5.3.8.zip
http://files.jrsoftware.org/is/5/issrc-5.3.9.zip
http://files.jrsoftware.org/is/5/issrc-5.3.10.zip
http://files.jrsoftware.org/is/5/issrc-5.3.11.zip
http://files.jrsoftware.org/is/5/issrc-5.4.0.zip
http://files.jrsoftware.org/is/5/issrc-5.4.1.zip
http://files.jrsoftware.org/is/5/issrc-5.4.2.zip
);

sub tag {
	my ($zip, $msg, $tag) = @_;
	system("$git rm -r .");
	system("$unzip $zip");
	system("$git add .");
	system("$git commit -m '$msg'");
	print("The error about the missing tag can be ignored.\n");
	system("$git tag -d $tag");
	system("$git tag $tag");
}

system($wget, @sources);

system("$git clone $giturl $srcdir");
chdir($srcdir);
system("$git checkout $firstcommit");
system("$git checkout -b $branch");

for my $url (@sources) {
	my ($zipfile, $major, $minor, $micro) = ($url =~ /(issrc-([0-9])\.([0-9])\.([0-9]{1,2})(-beta)?\.zip)/);
	tag("../$zipfile", "$major.$minor.$micro", "is-$major\_$minor\_$micro");
}

system("$git checkout master");
