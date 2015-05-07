#!/usr/bin/perl

use warnings;
use strict;

use DBI;
use Time::Piece;
use LWP::Simple;
use JSON qw/from_json/;

my $dbh = DBI->connect("DBI:mysql:landtagbw", "landtagbw", "landtagbw", {mysql_enable_utf8 => 1,});
my $db_init_s = $dbh->prepare('SELECT id FROM initiativen WHERE periode = ? AND periode_id = ?');
my $db_ds_s = $dbh->prepare('SELECT id FROM drucksachen WHERE periode = ? AND periode_id = ?');

my $initurl = 'http://lt.sproesser.name/init.pl';
my $dsurl = 'http://lt.sproesser.name/ds.pl';

my $year = localtime->strftime('%Y');
my $month = localtime->strftime('%m');

my @years = (2015, 2014, 2013, 2012, 2011, 2010, 2009);
my @months = (1..12);

# hole alle abgeordneten
my $db_abgeordnete_s = $dbh->prepare('SELECT id, name, partei FROM mdl');
$db_abgeordnete_s->execute();
my $mdl_liste = $db_abgeordnete_s->fetchall_hashref('id');
1;

# hole drucksachenliste von einem monat
for my $year (@years) {
	for my $month (@months) {
		warn "Processing $month / $year\n";
my $ds_content = get($dsurl.'?searchYear='.$year.'&searchMonth='.$month);
my $ds = from_json($ds_content, {utf8 => 1});

for my $id (keys %$ds) {
	warn "\tProcessing Drucksache $id...\n";
	# alle, die noch nicht in der db sind:
	my ($periode, $periode_id) = (split(/\//,$id));
	$db_ds_s->execute($periode, $periode_id);
	unless ($db_ds_s->rows) {
		warn "\t\tAdding to DB...\n";
		# * pdf holen
		my $filename = $ds->{$id}->{link};
		$filename =~ s/.*\///;
		getstore($ds->{$id}->{link}, '/tmp/'.$filename);
		# * nach text wandeln
		my $textcontent = `/usr/bin/pdftotext -eol unix /tmp/$filename -`;
		# * text in die db werfen (drucksachen_volltexte)
		$dbh->do('INSERT INTO drucksachen_volltexte (periode, periode_id, text) VALUES (?, ?, ?)',
					undef, $periode, $periode_id, $textcontent);
		# * datum umwandeln
		my ($day, $month, $year) = ($ds->{$id}->{date} =~ /(\d+)\.(\d+)\.(\d+)/);
		$ds->{$id}->{date} = join('-',($year, $month, $day));
		# * metadaten in die db werfen (drucksachen)
		$dbh->do('INSERT INTO drucksachen (periode, periode_id, link, datum, titel) VALUES (?, ?, ?, ?, ?)',
					undef, $periode, $periode_id, $ds->{$id}->{link}, $ds->{$id}->{date}, $ds->{$id}->{title});
	}
}

# hole initiativenliste von einem monat
my $init_content = get($initurl.'?searchYear='.$year.'&searchMonth='.$month);
my $init = from_json($init_content, {utf8 => 0});

for my $id (keys %$init) {
	warn "\tProcessing Initiative $id...\n";
	# alle, die noch nicht in der db sind:
	my ($periode, $periode_id) = (split(/\//,$id));
	$db_init_s->execute($periode, $periode_id);
	unless ($db_init_s->rows) {
		warn "\t\tAdding to DB...\n";
		my $flag = 0;
		# * pdf holen
		my $filename = $init->{$id}->{link};
		$filename =~ s/.*\///;
		getstore($init->{$id}->{link}, '/tmp/'.$filename);
		# * nach text wandeln
		my $textcontent = `/usr/bin/pdftotext -eol unix /tmp/$filename -`;
		# * text in die db werfen (initiativen_volltexte)
		$dbh->do('INSERT INTO initiativen_volltexte (periode, periode_id, text) VALUES (?, ?, ?)',
					undef, $periode, $periode_id, $textcontent);
		# * text analysieren (antragsteller)
		my $mdl_ids;
		if ($init->{$id}->{art} eq 'Kleine Anfrage') {
			my @parteien = split(/\s*,\s*/,$init->{$id}->{urheber});
			s/_/\//g for (@parteien);
			for my $mdl_id (keys %$mdl_liste) {
				my $parteimatch = 0;
				for (@parteien) {
					$parteimatch = 1 if ($mdl_liste->{$mdl_id}->{partei} eq $_)
				}
				next unless $parteimatch;
				
				if ($textcontent =~ /\b$mdl_liste->{$mdl_id}->{name}\b/) {
					if ($mdl_liste->{$mdl_id}->{name} eq 'Wahl') {
						# Sonderfall
						$flag = 1;
					}
					push(@$mdl_ids, $mdl_id);
				}
			}
		}
		if ($init->{$id}->{art} eq 'Kleine Anfrage') {
			$init->{$id}->{art} = 'kleine_anfrage';
		} elsif ($init->{$id}->{art} eq 'Antrag') {
			$init->{$id}->{art} = 'antrag';
		} else {
			$init->{$id}->{art} = 'grosse_anfrage';
		}
		# * datum umwandeln
		my ($day, $month, $year) = ($init->{$id}->{date} =~ /(\d+)\.(\d+)\.(\d+)/);
		$init->{$id}->{date} = join('-',($year, $month, $day));
		# * metadaten in die db werfen (initiativen)
		$dbh->do('INSERT INTO initiativen (periode, periode_id, urheber_partei, link, datum, art, titel, review) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
					undef, $periode, $periode_id, $init->{$id}->{urheber}, $init->{$id}->{link}, $init->{$id}->{date}, $init->{$id}->{art}, $init->{$id}->{title}, $flag);
		# * antragsteller in die db werfen (mdl_initiativen)
		my $insert_id = $dbh->{'mysql_insertid'};
		for my $mdl_id (@$mdl_ids) {
			$dbh->do('INSERT INTO mdl_initiativen (mdl_id, initiativen_id) VALUES (?, ?)',
						undef, $mdl_id, $insert_id);
		}
	}
}
} #month
}# year
