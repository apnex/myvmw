#!/usr/bin/perl
package vmwDownload;
use lib '/root/';
use Data::Dumper;
use JSON::PP;
use LWP::UserAgent;
use HTML::TableExtract;
use Cwd;
use xview;

sub new {
	my $self = {};
	my $class = shift;
	return bless($self, $class);
}

sub build {
	my $self = shift;
	my $ua = shift;
	$ua->show_progress(1);

	## load index
	#my $cwd = Cwd::cwd();
	#my $dir = $cwd.'/download/';
	my $dir = '/vmwfiles/';
	my $handle = $dir.'product.json';
	my @lines;
	if(open($handle, "<", $handle)) {
		chomp(@lines = <$handle>);
		close $handle;
	} else {
		die("No file found! ($handle missing or invalid)\n");
	}
	my $content = join('', @lines);
	
	$coder = JSON::PP->new->ascii->pretty->allow_nonref;
	my $product = $coder->decode($content);
	#print Dumper($product);
	
	# req03
	my $host = "my.vmware.com";
	my $uri;
	my @allData;
	foreach my $item(@{$product}) { # build a tableMap.pm
		$item->{link} =~ m/downloadGroup=([^&]+)/g;
		$uri = $item->{link};
		my $url = "https://$host$uri";
		print("## ".$item->{name}." ##\n");
		my $response = $ua->get($url); # call target download URL!
		if ($response->is_success) {
			my $data = buildTable($response->decoded_content);
			push(@allData, @{$data});
		} else {
			die $response->status_line;
		}
	}

	writeJson($dir.'files.json', \@allData);
	my $cols = [
		'name',
		'fileName',
		'fileDate',
		'fileSize',
		'fileType',
		'download'
	];
	# map download
	my @data;
	foreach my $item(@allData) {
		if($item->{download}) {
			$item->{download} = 'Yes';
		} else {
			$item->{download} = 0;
		}
		push(@data, $item);
	}
	#print Dumper(@data);
	my $view = xview->new($cols,  \@data);
	$view->out();
}

sub buildTable {
	my $doc = shift;
	my $te = HTML::TableExtract->new(
		depth => 0,
		count => 3,
		keep_html => 1
	);
	$te->parse($doc);

	my @data;
	foreach my $ts($te->tables) {
		my $rows = $ts->rows;
		my ($x, $y) = $ts->coords;
		shift(@{$rows});
		foreach my $item(@{$rows}) {
			if($item->[0] =~ m/<div class="infoDownload">/g) {
				my $node = buildFileItem($item->[0]);
				push(@data, $node);
			}
		}
	}
	return \@data;
}

sub buildFileItem {
	my $string = shift;
	$string = clean($string);
	#print($string."\n");

	# get fileName, fileSize, fileType
	my $name;
	my $fileSize;
	my $fileType;
	if($string =~ m/<div class="infoDownload"><strong>(.*?)<\/strong>/) {
		$name = $1;
	}
	if($string =~ m/<span class="fileSize label">File size<\/span>: (.*?)<br>/) {
		$fileSize = $1;
	}
	if($string =~ m/<span class="fileType label">File type<\/span>: (.*?)<br>/) {
		$fileType = $1;
	}

	# get fileName, releaseDate, buildNumber
	my $fileName;
	my $fileDate;
	my $buildNum;
	if($string =~ m/<span class="fileNameHolder">(.*?)<\/span>/){
		$fileName = $1;
	}
	if($string =~ m/<span class="releaseDate label">Release Date<\/span>: (.*?)<br>/) {
		$fileDate = $1;
	}
	if($string =~ m/<span class="build label">Build Number<\/span>: ([\d]+)/) {
		$buildNum = $1;
	}

	# get description, hashMd5, hashSha1, hashSha256
	my $descr;
	my $md5sum;
	my $sha1sum;
	my $sha256sum;
	if($string =~ m/<div class="col2"><p>.*?<br>(.*)?<\/p>/) {
		$descr = $1;
	}
	if($string =~ m/<span class="MD5SUM label">MD5SUM<\/span>: ([0-9a-f]+)<br>/) {
		$md5sum = $1;
	}
	if($string =~ m/<span class="checksum1 label">SHA1SUM<\/span>: ([0-9a-f]+)<br>/) {
		$sha1sum = $1;
	}
	if($string =~ m/<span class="MD5SUM label">SHA256SUM<\/span>: ([0-9a-f]+)<\/div>/) {
		$sha256sum = $1;
	}
	my $node = {
		name		=> $name,
		fileName	=> $fileName,
		fileDate	=> $fileDate,
		fileSize	=> $fileSize,
		fileType	=> $fileType,
		buildNum	=> $buildNum,
		descr		=> $descr,
		md5sum		=> $md5sum,
		sha1sum		=> $sha1sum,
		sha256sum	=> $sha256sum,
		download	=> getEulaButton($string)
	};
	return $node;
}

sub clean {
	my $text = shift; # strip spaces, non-ascii and newlines!
	$text =~ s/\R//g; # remove all newlines
	$text =~ s/^[\s]+//; # from start of string
	$text =~ s/[\s]+$//; # from end of string
	$text =~ s/[\s]{2,}/ /g; # replace double-spaces with single space
	$text =~ s/[\s]+<\//<\//g; # remove spaces before a closing html tag
	$text =~ s/>\s</></g; # remove contiguous spaces between 2 html tags
	$text =~ s/[\s]+<br>/<br>/g; # remove spaces before <br> tag
	$text =~ s/[^[:ascii:]]//g; # strip non-ascii
	return $text;
}

sub getEulaButton {
	my $item = shift;
	if($item =~ m/onclick="checkEulaAndPerform\(([^\)]+).*Download Now/g) {
		return buildFile($1);
	} else {
		return 0;
	}
}

sub buildFile {
	my $string = shift;
	my @out;
	my @values = split(',', $string);
	foreach my $val(@values) {
		if($val =~ m/([^']+)/g) {
			push(@out, $1);
		} else {
			push(@out, "");
		}
	}
	my $node = {
		downloadGroupCode	=> $out[0],
		downloadFileId		=> $out[1],
		vmware			=> 'downloadBinary',
		baseStr			=> $out[2],
		hashKey			=> $out[3],
		tagId			=> $out[4],
		productId		=> $out[5],
		uuId			=> $out[6]
	};
	return $node;
}

sub writeJson {
	my $handle = shift;
	my $data = shift;
	if(open($handle, ">", $handle)) {
		my $json = JSON::PP->new->utf8->space_after->pretty->encode($data);
		print $handle($json);
		close($handle);
	} else {
		die("Failed to create file $handle!\n");
	}
}

# output table
sub view {
	my $table = shift;
	my $cols = [
		'name',
		'date',
		'link'
	];

	my $view = xview->new($cols,  \@data);
	$view->out();
}

1;
