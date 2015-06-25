package Landtag::BW;
use Dancer2;
use Dancer2::Plugin::Database;
use Dancer2::Plugin::Ajax;

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

get '/initiativen' => sub {
	my $sth = database->prepare('SELECT id, periode, periode_id, link, datum, titel, urheber_partei, art FROM initiativen');
    $sth->execute();
    my $dbresult = $sth->fetchall_hashref('id');
	my $result;
	
	for my $id (keys %$dbresult) {
		push(@$result, {periode => $dbresult->{$id}->{periode},
						periode_id => $dbresult->{$id}->{periode_id},
						link => $dbresult->{$id}->{link},
						datum => $dbresult->{$id}->{datum},
						urheber_partei => $dbresult->{$id}->{urheber_partei},
						art => $dbresult->{$id}->{art},
						titel => $dbresult->{$id}->{titel}});
	}
	
	template 'initiativen', {
		titel => 'Initiativen',
		ds => $result,
	};
};

get '/initiativen/kleine_anfragen' => sub {
	my $sth = database->prepare('SELECT id, periode, periode_id, link, datum, titel, urheber_partei, art FROM initiativen WHERE art = \'kleine_anfrage\'');
    $sth->execute();
    my $dbresult = $sth->fetchall_hashref('id');
	my $result;
	
	for my $id (keys %$dbresult) {
		my $sth_2 = database->prepare('SELECT mdl.id AS mdl_id, mdl.vorname AS vorname, mdl.name AS name, mdl.partei AS partei, mdl.wahlkreis AS wahlkreis FROM mdl, mdl_initiativen WHERE mdl.id = mdl_initiativen.mdl_id AND mdl_initiativen.initiativen_id = ?');
		$sth_2->execute($id);
		my $mdl_result = $sth_2->fetchall_hashref('mdl_id');
	
		push(@$result, {periode => $dbresult->{$id}->{periode},
						periode_id => $dbresult->{$id}->{periode_id},
						link => $dbresult->{$id}->{link},
						datum => $dbresult->{$id}->{datum},
						urheber_partei => $dbresult->{$id}->{urheber_partei},
						mdl => $mdl_result,
						art => $dbresult->{$id}->{art},
						titel => $dbresult->{$id}->{titel}});
	}
	
	template 'initiativen', {
		titel => 'Kleine Anfragen',
		ds => $result,
	};
};

get '/initiativen/grosse_anfragen' => sub {
	my $sth = database->prepare('SELECT id, periode, periode_id, link, datum, titel, urheber_partei, art FROM initiativen WHERE art = \'grosse_anfrage\'');
    $sth->execute();
    my $dbresult = $sth->fetchall_hashref('id');
	my $result;
	
	for my $id (keys %$dbresult) {
		push(@$result, {periode => $dbresult->{$id}->{periode},
						periode_id => $dbresult->{$id}->{periode_id},
						link => $dbresult->{$id}->{link},
						datum => $dbresult->{$id}->{datum},
						urheber_partei => $dbresult->{$id}->{urheber_partei},
						art => $dbresult->{$id}->{art},
						titel => $dbresult->{$id}->{titel}});
	}
	
	template 'initiativen', {
		titel => 'Große Anfragen',
		ds => $result,
	};
};

get '/initiativen/antraege' => sub {
	my $sth = database->prepare('SELECT id, periode, periode_id, link, datum, titel, urheber_partei, art FROM initiativen WHERE art = \'antrag\'');
    $sth->execute();
    my $dbresult = $sth->fetchall_hashref('id');
	my $result;
	
	for my $id (keys %$dbresult) {
		push(@$result, {periode => $dbresult->{$id}->{periode},
						periode_id => $dbresult->{$id}->{periode_id},
						link => $dbresult->{$id}->{link},
						datum => $dbresult->{$id}->{datum},
						urheber_partei => $dbresult->{$id}->{urheber_partei},
						art => $dbresult->{$id}->{art},
						titel => $dbresult->{$id}->{titel}});
	}
	
	template 'initiativen', {
		titel => 'Anträge',
		ds => $result,
	};
};

get '/initiative/:periode/:periode_id' => sub {
	my $sth = database->prepare('SELECT initiativen.datum as datum, initiativen.titel as titel, initiativen_volltexte.text as text FROM initiativen, initiativen_volltexte WHERE initiativen.periode = initiativen_volltexte.periode AND initiativen.periode_id = initiativen_volltexte.periode_id AND initiativen.periode = ? AND initiativen.periode_id = ?');
	$sth->execute(params->{periode}, params->{periode_id});
	my $result = $sth->fetchrow_hashref();
	
	template 'initiative', {
		doc => $result,
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

get '/karte' => sub {
	template 'karte';
};

get '/herrenlose_anfragen' => sub {
};

true;
