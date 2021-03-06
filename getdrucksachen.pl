#!/usr/bin/perl

use warnings;
use strict;

use Time::Piece;
use LWP::Simple qw/get/;
use Web::Scraper;
use utf8;
use Encode qw/decode encode/;
use JSON;

use CGI qw/:standard/;

# CGI-Parameters
#   searchYear (YYYY/YY) default: current year
#   searchMonth (M/MM) default: current month
#   outputFormat (json,prettyjson,csv) default: prettyjson

my $cgi = new CGI;

my $outputFormat = $cgi->param('outputFormat');
$outputFormat = 'prettyjson' unless ($outputFormat);
# sanizite input
$outputFormat = 'prettyjson' if (lc($outputFormat) ne 'json' and lc($outputFormat) ne 'csv');

my $searchYear = $cgi->param('searchYear');
$searchYear = localtime->strftime('%Y') unless ($searchYear);
# sanitize input
if ($searchYear !~ /^\d\d(\d\d)?$/) {
	$searchYear = localtime->strftime('%Y');
} else {
	if ($searchYear < 50) {
		$searchYear += 2000;
	} elsif ($searchYear < 100) {
		$searchYear += 1900;
	}
}

my $searchMonth = $cgi->param('searchMonth');
$searchMonth = localtime->strftime('%m') unless ($searchMonth);
# sanitize input
if ($searchMonth !~ /^\d\d?$/) {
	$searchMonth = localtime->strftime('%m');
} else {
	$searchMonth = '0' . $searchMonth if (length($searchMonth) == 1);
}

my $baseurl = 'http://www.landtag-bw.de';

my $basesearch = $baseurl . '/cms/render/live/de/sites/LTBW/home/dokumente/die-initiativen/drucksachen/contentBoxes/suche-drucksachen.html';

# Parameters for Interface:
#   searchYear (YYYY)
#   searchMonth (MM)

#my $year = localtime->strftime('%Y');
#my $month = localtime->strftime('%m');
#my ($lastyear, $lastmonth);
#if ($month == 1) {
#	$lastyear = $year - 1;
#	$lastmonth = 12;
#} else {
#	$lastyear = $year;
#	$lastmonth = $month - 1;
#}

#$lastmonth = '0' . $lastmonth if (length($lastmonth) == 1);

my $content = get($basesearch.'?searchYear='.$searchYear.'&searchMonth='.$searchMonth);

my $scraper = scraper {
   process "div.result", "drucksachen[]" => scraper {
       process ".kategorie > p", meta => 'TEXT';
       process 'h3 > a', link => '@href';
       process 'h3 > a', title => 'TEXT';
   };
};

my $ds = $scraper->scrape($content);

my $items;

for my $item (sort sortMetaDate @{$ds->{drucksachen}}) {
	my $drucksache_id;
	my $date;
	my $link;
	my $title;
	($drucksache_id, $date) = (encode('UTF-8',$item->{meta}) =~ /(\d+\/\d+).*(\d\d\.\d\d\.\d\d\d\d)/);
	$link = $baseurl . (substr($item->{link},0,1) eq '/' ? '' : '/') . $item->{link};
	$title = encode('UTF-8', $item->{title});
	$items->{$drucksache_id} = {date => $date,
								link => $link,
								title => $title};
}

if (lc($outputFormat) eq 'csv') {
	print $cgi->header(-type => 'text/csv',
						-charset => 'utf-8');
	outputCSV($items);
} elsif (lc($outputFormat) eq 'json') {
	print $cgi->header(-type => 'application/json',
						-charset => 'utf-8');
	outputJSON($items,0);
} elsif (lc($outputFormat) eq 'prettyjson') {
	print $cgi->header(-type => 'application/json',
						-charset => 'utf-8');
	outputJSON($items,1);
}


sub outputCSV {
	my $items = shift;
	print "drucksache,datum,link,titel\n";

	for my $id (sort sortRefDate keys %$items) {
		print $id.",".$items->{$id}->{date}.",\"".$items->{$id}->{link}."\",\"".$items->{$id}->{title}."\"\n";
	}
}

sub outputJSON {
	my $items = shift;
	my $pretty = shift;
	if ($pretty) {
		$pretty = 1;
	} else {
		$pretty = 0;
	}
	print to_json($items, {pretty => $pretty});
}

sub sortMetaDate {
	return sortDate($b->{meta},$a->{meta});
}

sub sortDate {
	my ($a, $b) = (shift, shift);
	my ($a_d, $a_m, $a_y) = ($a =~ /(\d\d)\.(\d\d)\.(\d\d\d\d)/);
	my ($b_d, $b_m, $b_y) = ($b =~ /(\d\d)\.(\d\d)\.(\d\d\d\d)/);
	return $b_y <=> $a_y
		|| $b_m <=> $a_m
		|| $b_d <=> $a_d;
	
}

sub sortRefDate {
	return sortDate($items->{$a}->{date}, $items->{$b}->{date});
}
