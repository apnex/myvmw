#!/usr/bin/perl
package vmwIndex;
use Data::Dumper;
use Cwd;
use JSON::PP;
use LWP::UserAgent;

sub new {
	my $self = {};
	my $class = shift;
	return bless($self, $class);
}

sub build {
	my $self = shift;
	my $ua = shift;
	# check is ua is actually passed

	#my $cwd = Cwd::cwd();
	#my $dir = $cwd.'/download/';
	my $dir = '/vmwfiles/';
	# request index page
	my $host = "my.vmware.com";
	my $uri = "/group/vmware/downloads?p_p_id=ProductIndexPortlet_WAR_itdownloadsportlet&p_p_lifecycle=2&p_p_state=normal&p_p_mode=view&p_p_resource_id=productsAtoZ&p_p_cacheability=cacheLevelPage&p_p_col_id=column-6&p_p_col_pos=1&p_p_col_count=2";
	my $url = "https://$host$uri";
	my $response = $ua->get($url);
	if ($response->is_success) {
		my $content = $response->decoded_content;
		my $coder = JSON::PP->new->ascii->pretty->allow_nonref;
		my $index = buildIndex($coder->decode($content));

		# hack to add NSX-T
		# permanent solution is to incorporate indexing of all versions of a product
		push(@{$index}, {
			name => 'VMware NSX-T',
			link => './info/slug/networking_security/vmware_nsx/2_x'
		});

		my $handle = $dir.'index.json';
		if(open($handle, ">", $handle)) {
			my $json = JSON::PP->new->utf8->space_after->pretty->encode($index);
			print $handle($json);
		        close($handle);
		} else {
			die("Failed to create file index.json!\n");
		}
		close($handle);
		return $index;
	} else {
		my $error = $response->status_line."\n";
		$error .= "ERROR: Invalid username or password, please check credentials in config.json, or run 'myvmw help' for help";
		die $error;
		return 0;
	}
	
}

# build index.json
sub buildIndex {
	my $json = shift;
	my @data;
	my $list = $json->{productCategoryList}->[0]->{proList};
	foreach my $item(@{$list}) {
		my $new = {};
		$new->{name} = $item->{name};
		foreach $action(@{$item->{actions}}) {
			if($action->{linkname} eq 'View Download Components') {
				$new->{link} = $action->{target};
				last;
			}
		}
		push(@data, $new);
	}
	return \@data;
}

1;
