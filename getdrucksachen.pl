#!/usr/bin/perl

use warnings;
use strict;

use Time::Piece;

use LWP::Simple qw/get/;

use Web::Scraper;

use utf8;

use Encode qw/decode encode/;

my $baseurl = 'http://www.landtag-bw.de/';

my $basesearch = $baseurl . 'cms/render/live/de/sites/LTBW/home/dokumente/die-initiativen/drucksachen/contentBoxes/suche-drucksachen.html';

# Parameters:
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

my $content = get($basesearch.'?searchYear='.$year.'&searchMonth='.$month);

my $scraper = scraper {
   process "div.result", "drucksachen[]" => scraper {
       # And, in that array, pull in the elementy with the class
       # "entry-content", "entry-date" and the link
       process ".kategorie > p", meta => 'TEXT';
       process 'h3 > a', link => '@href';
       process 'h3 > a', title => 'TEXT';
   };
};

my $ds = $scraper->scrape($content);

my $drucksachen;

print "drucksache,datum,link,titel\n";

for my $item (sort sortDate @{$ds->{drucksachen}}) {
	my $drucksache_id;
	my $date;
	my $link;
	my $title;
	($drucksache_id, $date) = (encode('UTF-8',$item->{meta}) =~ /(\d+\/\d+).*(\d\d\.\d\d\.\d\d\d\d)/);
	$link = $baseurl . $item->{link};
	$title = encode('UTF-8', $item->{title});
	1;
	print $drucksache_id.",".$date.",\"".$link."\",\"".$title."\"\n";
}

$content = get($basesearch.'?searchYear='.$lastyear.'&searchMonth='.$lastmonth);

$ds = $scraper->scrape($content);
for my $item (sort sortDate @{$ds->{drucksachen}}) {
	my $drucksache_id;
	my $date;
	my $link;
	my $title;
	($drucksache_id, $date) = (encode('UTF-8',$item->{meta}) =~ /(\d+\/\d+).*(\d\d\.\d\d\.\d\d\d\d)/);
	$link = $baseurl . $item->{link};
	$title = encode('UTF-8', $item->{title});
	1;
	print $drucksache_id.",".$date.",\"".$link."\",\"".$title."\"\n";
}

sub sortDate {
	my ($a_d, $a_m, $a_y) = ($a->{meta} =~ /(\d\d)\.(\d\d)\.(\d\d\d\d)/);
	my ($b_d, $b_m, $b_y) = ($b->{meta} =~ /(\d\d)\.(\d\d)\.(\d\d\d\d)/);
	return $b_y <=> $a_y
		|| $b_m <=> $a_m
		|| $b_d <=> $a_d;
	
}
