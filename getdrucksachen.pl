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

my $baseurl = 'http://www.landtag-bw.de';

my $basesearch = $baseurl . '/cms/render/live/de/sites/LTBW/home/dokumente/die-initiativen/drucksachen/contentBoxes/suche-drucksachen.html';

# Parameters for Interface:
#   searchYear (YYYY)
#   searchMonth (MM)

my $year = localtime->strftime('%Y');
my $month = localtime->strftime('%m');
my ($lastyear, $lastmonth);
if ($month == 1) {
	$lastyear = $year - 1;
	$lastmonth = 12;
} else {
	$lastyear = $year;
	$lastmonth = $month - 1;
}

$lastmonth = '0' . $lastmonth if (length($lastmonth) == 1);

my $content = get($basesearch.'?searchYear='.$year.'&searchMonth='.$month);

my $scraper = scraper {
   process "div.result", "drucksachen[]" => scraper {
       process ".kategorie > p", meta => 'TEXT';
       process 'h3 > a', link => '@href';
       process 'h3 > a', title => 'TEXT';
   };
};

my $ds = $scraper->scrape($content);

my $drucksachen;

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

$content = get($basesearch.'?searchYear='.$lastyear.'&searchMonth='.$lastmonth);

$ds = $scraper->scrape($content);
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

#outputCSV($items);
outputJSON($items);

sub outputCSV {
	my $items = shift;
	print "drucksache,datum,link,titel\n";

	for my $id (sort sortRefDate keys %$items) {
		print $id.",".$items->{$id}->{date}.",\"".$items->{$id}->{link}."\",\"".$items->{$id}->{title}."\"\n";
	}
}

sub outputJSON {
	my $items = shift;
	print to_json($items, {pretty => 1});
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
