#!/usr/bin/perl

package Setup::Inno::Struct5203;

use strict;
use base qw(Setup::Inno::Struct5201);
use Encode;

=comment
  TSetupLanguageEntry = packed record
    { Note: LanguageName is Unicode }
    Name, LanguageName, DialogFontName, TitleFontName, WelcomeFontName,
      CopyrightFontName, Data, LicenseText, InfoBeforeText,
      InfoAfterText: String;
    LanguageID, LanguageCodePage: Cardinal;
    DialogFontSize: Integer;
    TitleFontSize: Integer;
    WelcomeFontSize: Integer;
    CopyrightFontSize: Integer;
    RightToLeft: Boolean;
  end;
=cut
sub SetupLanguages {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		my @strings = qw"Name LanguageName DialogFontName TitleFontName WelcomeFontName CopyrightFontName Data LicenseText InfoBeforeText InfoAfterText";
		for my $string (@strings) {
			$ret->[$i]->{$string} = $reader->ReadString();
		}
		# This is a wide string, but encoded as a regular one (length = number of bytes, not characters)
		$ret->[$i]->{LanguageName} = decode('UTF-16LE', $ret->[$i]->{LanguageName});
		$ret->[$i]->{LanguageID} = $reader->ReadCardinal();
		$ret->[$i]->{LanguageCodePage} = $reader->ReadCardinal();
		$ret->[$i]->{DialogFontSize} = $reader->ReadInteger();
		$ret->[$i]->{TitleFontSize} = $reader->ReadInteger();
		$ret->[$i]->{WelcomeFontSize} = $reader->ReadInteger();
		$ret->[$i]->{CopyrightFontSize} = $reader->ReadInteger();
		$ret->[$i]->{RightToLeft} = $reader->ReadBoolean();
	}
	return $ret;
}

1;

