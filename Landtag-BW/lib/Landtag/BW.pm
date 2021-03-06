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
	
	my $sth_reply = database->prepare('SELECT id FROM drucksachen WHERE periode = ? AND periode_id = ?');
	
	for my $id (keys %$dbresult) {
		$sth_reply->execute($dbresult->{$id}->{periode}, $dbresult->{$id}->{periode_id});
		my $antwort = 0;
		$antwort = 1 if ($sth_reply->fetchall_hashref('id'));
		push(@$result, {periode => $dbresult->{$id}->{periode},
						periode_id => $dbresult->{$id}->{periode_id},
						link => $dbresult->{$id}->{link},
						datum => $dbresult->{$id}->{datum},
						urheber_partei => $dbresult->{$id}->{urheber_partei},
						art => $dbresult->{$id}->{art},
						antwort => $antwort,
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

	my $sth_2 = database->prepare('SELECT mdl.id AS mdl_id, mdl.vorname AS vorname, mdl.name AS name, mdl.partei AS partei, mdl.wahlkreis AS wahlkreis FROM mdl, mdl_initiativen WHERE mdl.id = mdl_initiativen.mdl_id AND mdl_initiativen.initiativen_id = ?');
	my $sth_reply = database->prepare('SELECT id FROM drucksachen WHERE periode = ? AND periode_id = ?');
	
	for my $id (keys %$dbresult) {
		$sth_2->execute($id);
		my $mdl_result = $sth_2->fetchall_hashref('mdl_id');
	
		$sth_reply->execute($dbresult->{$id}->{periode}, $dbresult->{$id}->{periode_id});
		my $antwort = 0;
		$antwort = 1 if ($sth_reply->fetchrow_hashref());

		push(@$result, {periode => $dbresult->{$id}->{periode},
						periode_id => $dbresult->{$id}->{periode_id},
						link => $dbresult->{$id}->{link},
						datum => $dbresult->{$id}->{datum},
						urheber_partei => $dbresult->{$id}->{urheber_partei},
						mdl => $mdl_result,
						art => $dbresult->{$id}->{art},
						antwort => $antwort,
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
	
	#my $sth_kat = database->prepare('SELECT kategorien.name AS kategorie, ');
	
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

sub TranslateSuchbegriff {
	my ($suchbegriff) = (shift);
	my $search = join("* ", split(/\s+/, $suchbegriff)) . "*";
	return $search;
}

any ['get', 'post'] => '/suche' => sub {
	my $suchbegriff = params->{s};
	my $search = TranslateSuchbegriff($suchbegriff);
	
	my $ds_sth = database->prepare('SELECT id, periode, periode_id, titel, datum, link
	    FROM drucksachen
		WHERE MATCH(titel) AGAINST (? IN BOOLEAN MODE)');

	my $init_sth = database->prepare('SELECT id, periode, periode_id, titel, datum, link, urheber_partei
	    FROM initiativen
		WHERE MATCH(titel) AGAINST (? IN BOOLEAN MODE)');

	my $result;
	
	if (length($search) > 3) {
		
		$ds_sth->execute($search);
		$init_sth->execute($search);
		my $ds_result = $ds_sth->fetchall_hashref('id');
		my $init_result = $init_sth->fetchall_hashref('id');

		for my $id (keys %$init_result) {
			push(@{$result->{init}},
				{periode => $init_result->{$id}->{periode},
				 periode_id => $init_result->{$id}->{periode_id},
				 link => $init_result->{$id}->{link},
				 datum => $init_result->{$id}->{datum},
				 urheber_partei => $init_result->{$id}->{urheber_partei},
				 art => $init_result->{$id}->{art},
				 titel => $init_result->{$id}->{titel}});
		}
		
		for my $id (keys %$ds_result) {
			push(@{$result->{ds}},
				{periode => $ds_result->{$id}->{periode},
				 periode_id => $ds_result->{$id}->{periode_id},
				 link => $ds_result->{$id}->{link},
				 datum => $ds_result->{$id}->{datum},
				 titel => $ds_result->{$id}->{titel}});
		}

	}

	template 'suche', { ds => $result->{ds}, init => $result->{init}, suchbegriff => $search };
};

ajax '/suche/drucksachen' => sub {
	my $suchbegriff = params->{s};
	my $search = TranslateSuchbegriff($suchbegriff);
	my $ds_sth = database->prepare('SELECT id, periode, periode_id, titel, datum, link
	    FROM drucksachen
		WHERE MATCH(titel) AGAINST (? IN BOOLEAN MODE) ORDER BY periode DESC, periode_id DESC');

	my $result;

	if (length($search) > 3) {
		$ds_sth->execute($search);
		my $ds_result = $ds_sth->fetchall_hashref('id');
		for my $id (keys %$ds_result) {
			push(@{$result->{ds}},
				{periode => $ds_result->{$id}->{periode},
				 periode_id => $ds_result->{$id}->{periode_id},
				 link => $ds_result->{$id}->{link},
				 datum => $ds_result->{$id}->{datum},
				 titel => $ds_result->{$id}->{titel}});
		}
		
		if ($result->{ds}) {
			return to_json( $result->{ds} )
		}
	}
	return to_json( [] );
};

ajax '/suche/initiativen' => sub {
	my $suchbegriff = params->{s};
	my $search = TranslateSuchbegriff($suchbegriff);
	$search = join("* ", split(/\s+/, $search)) . "*";

	my $init_sth = database->prepare('SELECT id, periode, periode_id, titel, datum, link, urheber_partei
	    FROM initiativen
		WHERE MATCH(titel) AGAINST (? IN BOOLEAN MODE) ORDER BY periode DESC, periode_id DESC');
		
	my $result;
	
	if (length($search) > 3) {
		$init_sth->execute($search);
		my $init_result = $init_sth->fetchall_hashref('id');
		
		for my $id (keys %$init_result) {
			push(@{$result->{init}},
				{periode => $init_result->{$id}->{periode},
				 periode_id => $init_result->{$id}->{periode_id},
				 link => $init_result->{$id}->{link},
				 datum => $init_result->{$id}->{datum},
				 urheber_partei => $init_result->{$id}->{urheber_partei},
				 art => $init_result->{$id}->{art},
				 titel => $init_result->{$id}->{titel}});
		}
		if ($result->{init}) {
			return to_json( $result->{init} )
		}
	}
	return to_json( [] );
};

ajax '/suche/:s' => sub {
	my $suchbegriff = params->{s};
	my $search = TranslateSuchbegriff($suchbegriff);
	my $ds_sth = database->prepare('SELECT id, periode, periode_id, titel, datum, link
	    FROM drucksachen
		WHERE MATCH(titel) AGAINST (? IN BOOLEAN MODE)');

	my $init_sth = database->prepare('SELECT id, periode, periode_id, titel, datum, link, urheber_partei
	    FROM initiativen
		WHERE MATCH(titel) AGAINST (? IN BOOLEAN MODE)');


	if (length($search) > 3) {
		$ds_sth->execute($search);
		$init_sth->execute($search);
		my $ds_result = $ds_sth->fetchall_hashref('id');
		my $init_result = $init_sth->fetchall_hashref('id');
		return to_json( {ds => $ds_result, init => $init_result});
	} else {
		return to_json( {ds => {}, init => {}} );
	}
};


get '/kategorien' => sub {
	my $sth = database->prepare('SELECT id, name FROM kategorien');
	$sth->execute();
	my $db_result = $sth->fetchall_hashref('id');
	# show all kategorien
	# (maybe all suchbegriffe?)
	# form to add new Kategorie
	#debug($db_result);
	template 'kategorien', {
		kategorien => $db_result,
	}
};

post '/kategorien/neu' => sub {
	# Insert into database
	if (params->{neu_kategorie}) {
		my $sth = database->prepare('INSERT INTO kategorien (name) VALUES (?)');
		$sth->execute(params->{neu_kategorie});
	}
	redirect '/kategorien';
};

get '/kategorien/neu' => sub {
	my $sth = database->prepare('SELECT id, name FROM kategorien');
	$sth->execute();
	my $db_result = $sth->fetchall_hashref('id');
	# show all kategorien
	# (maybe all suchbegriffe?)
	# form to add new Kategorie
	#debug($db_result);
	template 'kategorien', {
		kategorien => $db_result,
		neu => 1,
	}
};

get '/kategorien/ohne' => sub {
	# show all kleine Anfragen without Kategorie
	# add field to add another Suchbegriff to a Kategorie
};

get '/kategorien/:kategorie_id' => sub {
	# show suchbegriffe
	my $sth = database->prepare('SELECT id, name FROM kategorien WHERE id = ?');
	$sth->execute(params->{kategorie_id});
	my $kategorie = $sth->fetchrow_hashref();
	
	$sth = database->prepare('SELECT id, suchbegriff FROM kategorien_suchbegriffe WHERE kategorien_id = ?');
	$sth->execute($kategorie->{id});

	my $db_result = $sth->fetchall_hashref('id');
	
	
	my $ds_sth = database->prepare('SELECT id, periode, periode_id, titel, datum, link
	    FROM drucksachen
		WHERE MATCH(titel) AGAINST (? IN BOOLEAN MODE)');

	my $init_sth = database->prepare('SELECT id, periode, periode_id, titel, datum, link, urheber_partei
	    FROM initiativen
		WHERE MATCH(titel) AGAINST (? IN BOOLEAN MODE)');
	
	my $ds_result = {};
	my $init_result = {};
	
	for my $id (keys %$db_result) {
		$ds_sth->execute(TranslateSuchbegriff($db_result->{$id}->{suchbegriff}));
		$init_sth->execute(TranslateSuchbegriff($db_result->{$id}->{suchbegriff}));
		
		my $ds_res = $ds_sth->fetchall_hashref('id');
		my $init_res = $init_sth->fetchall_hashref('id');
		
		$ds_result = {%$ds_result, %$ds_res};
		$init_result = {%$init_result, %$init_res};
		
	}

#	debug($ds_result);

	# show matching kleine Anfragen
	template 'kategorie', {
		name => $kategorie->{name},
		suchbegriffe => $db_result,
		ds => $ds_result,
		init => $init_result,
		kategorie_id => params->{kategorie_id}
#		neu => 1,
	}
};

post '/kategorien/:kategorie_id/neu' => sub {
	# Insert into database
	if (params->{suchbegriff}) {
		my $sth = database->prepare('INSERT INTO kategorien_suchbegriffe (kategorien_id, suchbegriff) VALUES (?, ?)');
		$sth->execute(params->{kategorie_id}, params->{suchbegriff});
	}
	redirect '/kategorien/'.params->{kategorie_id};
};


get '/kategorien/:kategorie_id/neu' => sub {
	# show suchbegriffe
	my $sth = database->prepare('SELECT id, name FROM kategorien WHERE id = ?');
	$sth->execute(params->{kategorie_id});
	my $kategorie = $sth->fetchrow_hashref();
	
	$sth = database->prepare('SELECT id, suchbegriff FROM kategorien_suchbegriffe WHERE kategorien_id = ?');
	$sth->execute($kategorie->{id});

	my $db_result = $sth->fetchall_hashref('id');
	
	#debug($db_result);
	
	my $ds_sth = database->prepare('SELECT id, periode, periode_id, titel, datum, link
	    FROM drucksachen
		WHERE MATCH(titel) AGAINST (? IN BOOLEAN MODE)');

	my $init_sth = database->prepare('SELECT id, periode, periode_id, titel, datum, link, urheber_partei
	    FROM initiativen
		WHERE MATCH(titel) AGAINST (? IN BOOLEAN MODE)');
	
	my $ds_result = {};
	my $init_result = {};
	
	for my $id (keys %$db_result) {
		$ds_sth->execute(TranslateSuchbegriff($db_result->{$id}->{suchbegriff}));
		$init_sth->execute(TranslateSuchbegriff($db_result->{$id}->{suchbegriff}));
		
		my $ds_res = $ds_sth->fetchall_hashref('id');
		my $init_res = $init_sth->fetchall_hashref('id');
		
		$ds_result = {%$ds_result, %$ds_res};
		$init_result = {%$init_result, %$init_res};
		
		$db_result->{$id}->{initiativen} = scalar keys %$init_res;
		$db_result->{$id}->{drucksachen} = scalar keys %$ds_res;
	}

#	debug($ds_result);

	# show matching kleine Anfragen
	template 'kategorie', {
		name => $kategorie->{name},
		kategorie_id => params->{kategorie_id},
		suchbegriffe => $db_result,
		ds => $ds_result,
		init => $init_result,
		neu => 1,
	}
};

get '/mdl' => sub {
	# Liste aller Parteien
	my $sth = database->prepare('SELECT partei FROM mdl GROUP BY partei');
	$sth->execute();
	my $parteien_hash = $sth->fetchall_hashref('partei');
	my $result;
	for my $partei (keys %$parteien_hash) {
		my $partei_lesbar = $partei;
		$partei =~ s!/!_!;
		push(@$result, {url => '/mdl/'.$partei, name => $partei_lesbar});
	}

	template 'liste', {
		titel => 'Liste der Parteien',
		liste => $result,
		zurueck_url => '/',
	}
};

get '/mdl/:partei' => sub {
	# Liste aller MdL
	my $partei = params->{'partei'};
	my $partei_lesbar = $partei;
	$partei_lesbar =~ s!_!/!;
	my $sth = database->prepare('SELECT id, vorname, name, wahlkreis, aktiv FROM mdl WHERE partei = ?');
	$sth->execute($partei_lesbar);
	my $mdl_hash = $sth->fetchall_hashref('id');
	
	my $result;
	for my $id (sort {$mdl_hash->{$a}->{name} cmp $mdl_hash->{$b}->{name} or $mdl_hash->{$a}->{vorname} cmp $mdl_hash->{$b}->{vorname}} keys %$mdl_hash) {
		push(@$result, {url => '/mdl/'.$partei.'/'.lc($id.'_'.$mdl_hash->{$id}->{vorname}.$mdl_hash->{$id}->{name}),
						name => $mdl_hash->{$id}->{name}.', '.$mdl_hash->{$id}->{vorname}.' (WK '.$mdl_hash->{$id}->{wahlkreis}.($mdl_hash->{$id}->{aktiv} ? ')' : ', inaktiv)')
					});
	}
	
	template 'liste', {
		titel => 'Liste der MDL der Fraktion \'' . $partei_lesbar.'\'',
		liste => $result,
		zurueck_url => '/mdl',
	}
};

get '/mdl/:partei/:name' => sub {
	# Liste aller Initiativen (+ Antwort)
	# Nur die Zahl am Anfang wird ausgewertet als Mysql-id
	my $sth = database->prepare('SELECT initiativen.id AS id, initiativen.periode AS periode, initiativen.periode_id AS periode_id, initiativen.link AS link, initiativen.datum AS datum, initiativen.titel AS titel, initiativen.urheber_partei AS urheber_partei, initiativen.art AS art FROM initiativen, mdl_initiativen WHERE initiativen.art = \'kleine_anfrage\' AND mdl_initiativen.initiativen_id = initiativen.id AND mdl_initiativen.mdl_id = ?');
	my $mdl = params->{name};
	my ($mdl_id) = ($mdl =~ /^(\d+)_/);
    $sth->execute($mdl_id);
    my $dbresult = $sth->fetchall_hashref('id');
	my $result;

	my $mdl_info = database->quick_select('mdl', {id => $mdl_id});

	my $sth_2 = database->prepare('SELECT mdl.id AS mdl_id, mdl.vorname AS vorname, mdl.name AS name, mdl.partei AS partei, mdl.wahlkreis AS wahlkreis FROM mdl, mdl_initiativen WHERE mdl.id = mdl_initiativen.mdl_id AND mdl_initiativen.initiativen_id = ?');
	my $sth_reply = database->prepare('SELECT id FROM drucksachen WHERE periode = ? AND periode_id = ?');
	
	for my $id (keys %$dbresult) {
		$sth_2->execute($id);
		my $mdl_result = $sth_2->fetchall_hashref('mdl_id');
	
		$sth_reply->execute($dbresult->{$id}->{periode}, $dbresult->{$id}->{periode_id});
		my $antwort = 0;
		$antwort = 1 if ($sth_reply->fetchrow_hashref());

		push(@$result, {periode => $dbresult->{$id}->{periode},
						periode_id => $dbresult->{$id}->{periode_id},
						link => $dbresult->{$id}->{link},
						datum => $dbresult->{$id}->{datum},
						urheber_partei => $dbresult->{$id}->{urheber_partei},
						mdl => $mdl_result,
						art => $dbresult->{$id}->{art},
						antwort => $antwort,
						titel => $dbresult->{$id}->{titel}});
	}
	
	template 'initiativen', {
		titel => 'Kleine Anfragen von MDL '.$mdl_info->{name}.', '.$mdl_info->{vorname}.', ('.$mdl_info->{partei}.')',
		ds => $result,
	};

};

get '/mdl/:partei/:name/neu' => sub {
};

get '/karte' => sub {
	template 'karte';
};

get '/herrenlose_anfragen' => sub {
};

true;
