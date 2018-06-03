#!/usr/bin/perl
package vmwFile;
use lib '/root/';
use Data::Dumper;
use JSON::PP;
use LWP::UserAgent;
use Digest::MD5::File qw(file_md5_hex);
use Cwd;
use vmwLogin;

my $file = $ARGV[0];
my $client = vmwFile->new();
$client->download($file);

sub new {
	my $self = {};
	my $class = shift;
	return bless($self, $class);
}

sub download {
	my $self = shift;
	my $fileName = shift;

	# read in JSON config
	#my $cwd = Cwd::cwd();
	#my $dir = $cwd.'/download/';
	my $dir = '/vmwfiles/';
	my $filename = $dir.'config.json';
	my $json = JSON::PP->new->ascii->pretty->allow_nonref;
	my $jsondata;
	if(open(my $json_file, '<', $filename)) {
	        local $/;
	        $jsondata = <$json_file>;
	        close($json_file);
	} else {
	        die("Download directory or config.json file missing! - please attach\n");
	}
	my $config = $json->decode($jsondata);
	
	#login
	print("Realigning inertial dampeners for: https://my.vmware.com\n");
	my $login = vmwLogin->new();
	my $ua = $login->login({
	        username => $config->{username},
	        password => $config->{password}
	});
	$ua->show_progress(1);
	
	## load index
	#my $cwd = Cwd::cwd();
	#my $dir = $cwd.'/download/';
	my $dir = '/vmwfiles/';
	my $handle = $dir.'files.json';
	my @lines;
	if(open($handle, "<", $handle)) {
		chomp(@lines = <$handle>);
		close $handle;
	} else {
		die("No file found! (missing or invalid)\n");
	}
	my $content = join('', @lines);
	$coder = JSON::PP->new->ascii->pretty->allow_nonref;
	my $files = $coder->decode($content);
	
	# get file details
	#my $filter = "VMware-VMvisor-Installer-6.5.0.update01-5969303.x86_64.iso";
	#my $filter = "nsx-l2vpn-client-ovf-6144198.tar.gz";
	my $node;
	foreach my $item(@{$files}) { # build a tableMap.pm
		if($item->{fileName} eq $fileName) {
			$node = $item;
			last;
		}
	}
	print Dumper($node);
	
	## download file
	#my $cwd = Cwd::cwd();
	#my $dir = $cwd.'/download/';
	my $dir = '/vmwfiles/';
	if($node) {
		if($node->{download}) {
			my $url = getFileUrl($node->{download});
			print($url."\n");
			my $response = $ua->get($url);
			if($response->is_success) {
				## download file
				my $coder = JSON::PP->new->ascii->pretty->allow_nonref;
				my $file = $coder->decode($response->decoded_content);
				my $res = $ua->mirror($file->{downloadUrl}, $dir.$file->{fileName});
				if($res->is_success) {
					my $digest = file_md5_hex($dir.$file->{fileName}); # check MD5
					if($digest eq $node->{md5sum}) {
						print("MD5 Match! local: [".$digest."] remote: [".$node->{md5sum}."]\n");
					} else {
						print("MD5 Fail! local: [".$digest."] remote: [".$node->{md5sum}."]\n");
					}
				}
			} else {
				die $response->status_line;
			}
		} else {
			print("No permissions to download file [".$node->{fileName}."]\n");
		}
	} else {
		print("File [$file] was not found on my.vmware.com\n");
	}
}

sub getFileUrl {
	my $params = shift;
	my $base = "https://my.vmware.com/group/vmware/details?p_p_id=ProductDetailsPortlet_WAR_itdownloadsportlet&p_p_lifecycle=2&p_p_state=normal&p_p_mode=view&p_p_resource_id=downloadFiles&p_p_cacheability=cacheLevelPage&p_p_col_id=column-6&p_p_col_count=1";
	my $string;
	foreach my $key(keys(%{$params})) {
		$string .= '&'.$key.'='.$params->{$key};
	}
	return $base.$string;
}

1;
