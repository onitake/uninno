#!/usr/bin/perl

use strict;
use Cwd;
use File::Temp;
use Getopt::Long;

my ($help, $parser, $git, $issrc, $version, $base) = (undef, './makeparser.pl', 'git', undef, undef, 'Setup::Inno::Struct');
GetOptions(
	"parser=s" => \$parser,
	"git=s" => \$git,
	"src=s" => \$issrc,
	"version=s" => \$version,
	"base=s" => \$base,
	"help" => \$help
);
if ($help || !defined($issrc) || !defined($version)) {
	print STDERR "Usage: makestruct.pl --src <issrc> --version <1.2.3[u]> [--parser <makeparser.pl>] [--git <git>] [--base <class>] [--help]\n";
	print STDERR "       issrc      the path to a clone of the innosetup source repository\n";
	print STDERR "       version    the version number to check out prior to parsing (with u suffix for unicode mode)\n";
	print STDERR "       parser     the path to the parser script (default: $parser)\n";
	print STDERR "       git        the path to the git program (default: $git)\n";
	print STDERR "       base       the name of the base class (default to $base)\n";
	print STDERR "       help       for this help text\n";
	exit 0;
}

my @types = qw(
	TSetupHeader
	TSetupLanguageEntry
	TSetupCustomMessageEntry
	TSetupPermissionEntry
	TSetupTypeEntry
	TSetupComponentEntry
	TSetupTaskEntry
	TSetupDirEntry
	TSetupFileEntry
	TSetupIconEntry
	TSetupIniEntry
	TSetupRegistryEntry
	TSetupDeleteEntry
	TSetupRunEntry
	TSetupFileLocationEntry
);

my ($major, $minor, $micro, $unicode) = ($version =~ /^([0-9])\.([0-9])\.([0-9]{1,2})(u?)/);
my $tag = sprintf('is-%u_%u_%u', $major, $minor, $micro);
my $module = sprintf('Struct%u%u%02u%s', $major, $minor, $micro, $unicode ? 'u' : '');
my $output = "$module.pm";
my $package = "Setup::Inno::$module";

sub checkout {
	my $dir = cwd();
	chdir($issrc);
	system($git, 'checkout', $tag) == 0 || die("Can't check out tag $tag");
	chdir($dir);
}

sub struct {
	my $temp = File::Temp->new();
	system($parser, '--input', $issrc . '/Projects/Struct.pas', '--output', $temp->filename, $unicode ? '--unicode' : '--ansi', map({ ('--type', $_) } @_)) == 0 || die("Can't run parser script");
	my $ret;
	while (<$temp>) {
		$ret .= $_;
	}
	return $ret;
}

print("Checking out tag $tag...\n");
checkout();

print("Writing to $output...\n");
open(my $out, '>', $output);

print("Writing header...\n");
print $out <<EOF;
package $package;
use strict;
use base '$base';
sub SetupHeader { my (\$self, \$reader) = \@_; return \$self->TSetupHeader(\$reader); }
sub SetupLanguages { my (\$self, \$reader, \$count) = \@_; return [ map { \$self->TSetupLanguageEntry(\$reader) } 0..\$count-1 ]; }
sub SetupCustomMessages { my (\$self, \$reader, \$count) = \@_; return [ map { \$self->TSetupCustomMessageEntry(\$reader) } 0..\$count-1 ]; }
sub SetupPermissions { my (\$self, \$reader, \$count) = \@_; return [ map { \$self->TSetupPermissionEntry(\$reader) } 0..\$count-1 ]; }
sub SetupTypes { my (\$self, \$reader, \$count) = \@_; return [ map { \$self->TSetupTypeEntry(\$reader) } 0..\$count-1 ]; }
sub SetupComponents { my (\$self, \$reader, \$count) = \@_; return [ map { \$self->TSetupComponentEntry(\$reader) } 0..\$count-1 ]; }
sub SetupTasks { my (\$self, \$reader, \$count) = \@_; return [ map { \$self->TSetupTaskEntry(\$reader) } 0..\$count-1 ]; }
sub SetupDirs { my (\$self, \$reader, \$count) = \@_; return [ map { \$self->TSetupDirEntry(\$reader) } 0..\$count-1 ]; }
sub SetupFiles { my (\$self, \$reader, \$count) = \@_; return [ map { \$self->TSetupFileEntry(\$reader) } 0..\$count-1 ]; }
sub SetupIcons { my (\$self, \$reader, \$count) = \@_; return [ map { \$self->TSetupIconEntry(\$reader) } 0..\$count-1 ]; }
sub SetupIniEntries { my (\$self, \$reader, \$count) = \@_; return [ map { \$self->TSetupIniEntry(\$reader) } 0..\$count-1 ]; }
sub SetupRegistryEntries { my (\$self, \$reader, \$count) = \@_; return [ map { \$self->TSetupRegistryEntry(\$reader) } 0..\$count-1 ]; }
sub SetupDelete { my (\$self, \$reader, \$count) = \@_; return [ map { \$self->TSetupDeleteEntry(\$reader) } 0..\$count-1 ]; }
sub SetupRun { my (\$self, \$reader, \$count) = \@_; return [ map { \$self->TSetupRunEntry(\$reader) } 0..\$count-1 ]; }
sub SetupFileLocations { my (\$self, \$reader, \$count) = \@_; return [ map { \$self->TSetupFileLocationEntry(\$reader) } 0..\$count-1 ]; }
sub TFileTime {
	my (\$self, \$reader) = \@_;
	my \$tlow = \$reader->ReadLongWord();
	my \$thigh = \$reader->ReadLongWord();
	my \$hnsecs = \$tlow | (\$thigh << 32);
	my \$secs = int(\$hnsecs / 10000000);
	my \$nsecs = (\$hnsecs - \$secs * 10000000) * 100;
	return DateTime->new(year => 1601, month => 1, day => 1, hour => 0, minute => 0, second => 0, nanosecond => 0)->add(seconds => \$secs, nanoseconds => \$nsecs);
}
sub HKEY {
	my (\$self, \$reader) = \@_;
	return \$reader->ReadLongWord();
}
sub DWORD {
	my (\$self, \$reader) = \@_;
	return \$reader->ReadLongWord();
}
EOF

print("Generating parser for " . join(' ', @types) . "...\n");
print($out struct(@types));
print($out "1;\n");
