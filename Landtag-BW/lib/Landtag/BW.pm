package Landtag::BW;
use Dancer2;
use Dancer2::Plugin::Database;

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

get '/drucksachen' => sub {
	my $sth = database->prepare('SELECT id, periode, periode_id, link, datum, titel FROM drucksachen');
    $sth->execute();
    my $dbresult = $sth->fetchall_hashref('id');
	my $result;
	
	for my $id (keys %$dbresult) {
		push(@$result, {periode => $dbresult->{$id}->{periode},
						periode_id => $dbresult->{$id}->{periode_id},
						link => $dbresult->{$id}->{link},
						datum => $dbresult->{$id}->{datum},
						titel => $dbresult->{$id}->{titel}});
	}
	template 'drucksachen', {
		ds => $result,
	};
};

get '/drucksache/:periode/:periode_id' => sub {
	my $sth = database->prepare('SELECT drucksachen.datum as datum, drucksachen.titel as titel, drucksachen_volltexte.text as text FROM drucksachen, drucksachen_volltexte WHERE drucksachen.periode = drucksachen_volltexte.periode AND drucksachen.periode_id = drucksachen_volltexte.periode_id AND drucksachen.periode = ? AND drucksachen_volltexte.periode_id = ?');
	$sth->execute(params->{periode}, params->{periode_id});
	my $result = $sth->fetchrow_hashref();
	
	template 'drucksache', {
		doc => $result,
	};
};

true;
