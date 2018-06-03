#!/usr/bin/perl
package vmwProduct;
use lib '/root/';
use HTML::TableExtract;
use Data::Dumper;
use Cwd;
use xview;
use JSON::PP;

sub new {
	my $self = {};
	my $class = shift;
	return bless($self, $class);
}

sub find {
	my $self = shift;
	my $ua = shift;
	my $filter = shift;

	## load index
	#my $cwd = Cwd::cwd();
	#my $dir = $cwd.'/download/';
	my $dir = '/vmwfiles/';
	my $handle = $dir.'index.json';
	my @lines;
	if(open($handle, "<", $handle)) {
	        chomp(@lines = <$handle>);
	        close $handle;
	} else {
	        die("No file found! (missing or invalid)\n");
	}
	my $content = join('', @lines);
	
	$coder = JSON::PP->new->ascii->pretty->allow_nonref;
	my $index = $coder->decode($content);
	
	# create product index
	my $host = "my.vmware.com";
	my $uri = "/group/vmware";
	foreach my $item(@{$index}) {
		if($item->{name} eq $filter) {
			$item->{link} =~ m/^\.(.*)$/g;
			$uri .= $1;
		}
	}
	
	my $url = "https://$host$uri";
	my $response = $ua->get($url); # call target download URL!
	if ($response->is_success) {
		my $handle = 'product.html';
		if(open($handle, ">:encoding(UTF-8)", $handle)) {
			print $handle($response->decoded_content);
			close($handle);
		} else {
			die("Failed to create file $handle!\n");
		}
	} else {
		die $response->status_line."\n";
	} # avoid a write??

	$self->makeProduct();
}

sub makeProduct {
	my $self = shift;

	# construct a JSON object of all values for future traversal
	my $doc = 'product.html';
	
	# get download items
	my $te = HTML::TableExtract->new(
		subtables => 1,
		attribs	=> { class => 'fn_startOpen pDownloads' }, # remove if all downloads required
		keep_html => 1
	);
	
	$te->parse_file($doc);
	my $tableCache = {};
	foreach my $ts($te->tables) {
		my $rows = $ts->rows;
		my ($x, $y) = $ts->coords;
		if($x == 1) {
			indexTable(buildTable($ts));
		}
	}
	my $result = collapseCache();
	#view($result);

	# write product.json
	#my $cwd = Cwd::cwd();
	#my $dir = $cwd.'/download/';
	my $dir = '/vmwfiles/';
	my $handle = $dir.'product.json';
	if(open($handle, ">", $handle)) {
		my $json = JSON::PP->new->utf8->space_after->pretty->encode($result);
		print $handle($json);
		close($handle);
	} else {
		die("Failed to create file $handle!\n");
	}
}

# collapse table
sub collapseCache {
	return [values(%{$tableCache})];
}

# index table
sub indexTable {
	my $table = shift;
	foreach my $item(@{$table}) {
		$tableCache->{$item->{name}} = $item; # dedupe on {name}
	}
}

# build table
sub buildTable {
	my $table = shift;
	my @data;
	foreach my $item($table->rows) {
		$item->[0] =~ s/[^[:ascii:]]//g; # strip non-ascii
		$item->[2] =~ m/^<a href="([^"]+)&rPId/g;
		push(@data, {
			name => $item->[0],
			date => $item->[1],
			link => $1
		});
	}
	return \@data;
}

# output table
sub view {
	my $table = shift;
	my $cols = [
		'name',
		'date',
		'link'
	];
	my $view = xview->new($cols,  $table);
	$view->out();
}

1;
