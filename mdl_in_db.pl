#!/usr/bin/perl

use warnings;
use strict;

use DBI;
use Encode qw/decode encode/;

my $dbh = DBI->connect("DBI:mysql:landtagbw", "landtagbw", "landtagbw");

my $mdl;

# hole mdl-liste aus Abgeordnete_WP15.csv
open(CSV,'<','Abgeordnete_WP15.csv');

my $first = 1;
while(<CSV>) {
	chomp;
	$_ = encode('UTF-8', $_);
	if ($first) {
		$first = 0;
		next;
	}
	my ($anrede, $nachname, $vorname, $titel, $blubber, $fraktion, $anschrift, $plz, $ort) = split(/;/,$_);
	$mdl->{lc($nachname.$vorname.$fraktion)} = {
		anrede => $anrede,
		nachname => $nachname,
		vorname => $vorname,
		titel => $titel,
		fraktion => $fraktion,
		aktiv => 1,
	};
}
close(CSV);

# hole wahlkreisnummer und inaktive aus mitglieder_wikipedia.txt
open(WIKI,'<','mitglieder_wikipedia.txt');

while(<WIKI>) {
	chomp;
	my ($vorname, $nachname, $fraktion, $wahlkreis) =
	($_ =~ /\{\{SortKeyName\|([^|]*)\|([^|]*).*?\}\} \|\| (.*?) \|\| \[\[.*?\|(\d\d)/);
	unless ($vorname) {
		 ($nachname, $vorname, $fraktion, $wahlkreis) =
			($_ =~ /\{\{SortKey\|([^,]*), ([^|]*).*?\}\} \|\| (.*?) \|\| \[\[.*?\|(\d\d)/);
	}
	next unless ($vorname);
#	| {{SortKeyName|Katrin|Altpeter}} || SPD || [[Landtagswahlkreis Waiblingen|15 Waiblingen]] || Zweitmandat || 24,2 % ||
	if (exists $mdl->{lc($nachname.$vorname.$fraktion)}) {
		$mdl->{lc($nachname.$vorname.$fraktion)}->{wahlkreis} = $wahlkreis;
	} else {
		$mdl->{lc($nachname.$vorname.$fraktion)} = {
			nachname => $nachname,
			vorname => $vorname,
			fraktion => $fraktion,
			wahlkreis => $wahlkreis,
			aktiv => 0,
		};
	}

}

my $sth = $dbh->prepare('INSERT INTO mdl (vorname, name, anrede, titel, partei, wahlkreis, aktiv) VALUES (?, ?, ?, ?, ?, ?, ?)');

for my $key (keys %$mdl) {
	my $p = $mdl->{$key};
	$sth->execute($p->{vorname}, $p->{nachname}, $p->{anrede}, $p->{titel}, $p->{fraktion}, $p->{wahlkreis}, $p->{aktiv});
}
