#!/usr/bin/perl

use warnings;
use strict;

use DBI;
use Time::Piece;
use LWP::Simple;
use JSON qw/from_json/;

my $dbh       = DBI->connect( "DBI:mysql:landtagbw", "landtagbw", "landtagbw", { mysql_enable_utf8 => 1, } );
my $db_init_s = $dbh->prepare('SELECT id FROM initiativen WHERE periode = ? AND periode_id = ?');
my $db_ds_s   = $dbh->prepare('SELECT id FROM drucksachen WHERE periode = ? AND periode_id = ?');


# hole alle abgeordneten
my $db_abgeordnete_s = $dbh->prepare('SELECT id, name, partei FROM mdl');
$db_abgeordnete_s->execute();
my $mdl_liste = $db_abgeordnete_s->fetchall_hashref('id');
1;

# gehe durch alle kleinen Anfragen
my $db_kleine_anfragen = $dbh->prepare('SELECT initiativen.id AS id, initiativen.titel AS titel, '.
	'initiativen.urheber_partei AS urheber_partei, initiativen_volltexte.text AS text '.
	'FROM initiativen, initiativen_volltexte '.
	'WHERE initiativen.periode = initiativen_volltexte.periode AND '.
	'initiativen.periode_id = initiativen_volltexte.periode_id AND '.
	'initiativen.art = \'kleine_anfrage\''.#);
	'AND initiativen.periode = 15 AND '.
	'initiativen.periode_id = 4744'
	);

$db_kleine_anfragen->execute();

while (my $line = $db_kleine_anfragen->fetchrow_hashref()) {
	1;
    my $mdl_ids;
    my @parteien = split( /\s*,\s*/, $line->{urheber_partei} );
    s/_/\//g for (@parteien);

    for my $mdl_id ( keys %$mdl_liste ) {
		my $parteimatch = 0;
        for (@parteien) {
			$parteimatch = 1 if ( lc($mdl_liste->{$mdl_id}->{partei}) eq lc($_) );
		}
		next unless $parteimatch;

#		if ( $line->{text} =~ /\b$mdl_liste->{$mdl_id}->{name}\b/ ) {
		if ( $line->{text} =~ /\n[^\n]*\b$mdl_liste->{$mdl_id}->{name}\b[^\n]*$mdl_liste->{$mdl_id}->{partei}\n/i ) {
			if ( $mdl_liste->{$mdl_id}->{name} eq 'Wahl' ) {
				# Sonderfall
				#$flag = 1;
			}
			push( @$mdl_ids, $mdl_id );
		}
	}
	1;
	
	
#                # * antragsteller in die db werfen (mdl_initiativen)
#                my $insert_id = $dbh->{'mysql_insertid'};
    for my $mdl_id (@$mdl_ids) {
		$dbh->do( 'INSERT INTO mdl_initiativen (mdl_id, initiativen_id) '.
			'SELECT * FROM (SELECT ?, ?) AS tmp WHERE NOT EXISTS ('.
				'SELECT mdl_id, initiativen_id FROM mdl_initiativen WHERE mdl_id = ? AND initiativen_id = ?'.
			') LIMIT 1',
				undef, $mdl_id, $line->{id}, $mdl_id, $line->{id} );
	}

}

