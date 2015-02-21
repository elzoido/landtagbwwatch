#!/usr/bin/perl

use warnings;
use strict;

use DBI;

my $dbh = DBI->connect("DBI:mysql:landtagbw", "landtagbw", "landtagbw");

# hole drucksachenliste von einem monat
# alle, die noch nicht in der db sind:
# * pdf holen
# * nach text wandeln
# * pdf und text in die db werfen (drucksachen_volltexte)
# * metadaten in die db werfen (drucksachen)


# hole initiativenliste von einem monat
# alle, die noch nicht in der db sind:
# * pdf holen
# * nach text wandeln
# * pdf und text in die db werfen (initiativen_volltexte)
# * text analysieren (antragsteller)
# * metadaten in die db werfen (initiativen)

1;
