#!/usr/bin/perl

use warnings;
use strict;

use DBI;
use Time::Piece;
use LWP::Simple;
use JSON qw/from_json/;

my $dbh = DBI->connect("DBI:mysql:landtagbw", "landtagbw", "landtagbw");
my $db_init_s = $dbh->prepare('SELECT id FROM initiativen WHERE periode = ? AND periode_id = ?');
my $db_ds_s = $dbh->prepare('SELECT id FROM drucksachen WHERE periode = ? AND periode_id = ?');

my $initurl = 'http://lt.sproesser.name/init.pl';
my $dsurl = 'http://lt.sproesser.name/ds.pl';

my $year = localtime->strftime('%Y');
my $month = localtime->strftime('%m');

# hole alle abgeordneten
my $db_abgeordnete_s = $dbh->prepare('SELECT id, name, partei FROM mdl');
$db_abgeordnete_s->execute();
my $mdl_liste = $db_abgeordnete_s->fetchall_hashref('id');
1;

# hole drucksachenliste von einem monat

my $ds_content = get($dsurl.'?searchYear='.$year.'&searchMonth='.$month);
my $ds = from_json($ds_content, {utf8 => 0});

for my $id (keys %$ds) {
	warn "Processing Drucksache $id...\n";
	# alle, die noch nicht in der db sind:
	my ($periode, $periode_id) = (split(/\//,$id));
	$db_ds_s->execute($periode, $periode_id);
	unless ($db_ds_s->rows) {
		# * pdf holen
		my $filename = $ds->{$id}->{link};
		$filename =~ s/.*\///;
		getstore($ds->{$id}->{link}, '/tmp/'.$filename);
		# * nach text wandeln
		my $textcontent = `/usr/bin/pdftotext -eol unix /tmp/$filename -`;
		# * (pdf und) text in die db werfen (drucksachen_volltexte)
		$dbh->do('INSERT INTO drucksachen_volltexte (periode, periode_id, text) VALUES (?, ?, ?)',
					undef, $periode, $periode_id, $textcontent);
		# TODO: PDF in die db werfen
		# * metadaten in die db werfen (drucksachen)
		$dbh->do('INSERT INTO drucksachen (periode, periode_id, link, datum, titel) VALUES (?, ?, ?, ?, ?)',
					undef, $periode, $periode_id, $ds->{$id}->{link}, $ds->{$id}->{date}, $ds->{$id}->{title});
	}
}

# hole initiativenliste von einem monat
my $init_content = get($initurl.'?searchYear='.$year.'&searchMonth='.$month);
my $init = from_json($init_content, {utf8 => 0});

for my $id (keys %$init) {
	warn "Processing Initiative $id...\n";
	# alle, die noch nicht in der db sind:
	my ($periode, $periode_id) = (split(/\//,$id));
	$db_init_s->execute($periode, $periode_id);
	unless ($db_init_s->rows) {
		my $flag = 0;
		# * pdf holen
		my $filename = $init->{$id}->{link};
		$filename =~ s/.*\///;
		getstore($init->{$id}->{link}, '/tmp/'.$filename);
		# * nach text wandeln
		my $textcontent = `/usr/bin/pdftotext -eol unix /tmp/$filename -`;
		# * (pdf und) text in die db werfen (initiativen_volltexte)
		$dbh->do('INSERT INTO initiativen_volltexte (periode, periode_id, text) VALUES (?, ?, ?)',
					undef, $periode, $periode_id, $textcontent);
		# TODO: PDF in die db werfen
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