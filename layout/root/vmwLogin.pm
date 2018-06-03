#!/usr/bin/perl
package vmwLogin;
use HTTP::Cookies;
use LWP::UserAgent;
use URI::Encode;
use Data::Dumper;

#my $vmw = vmwLogin->new();
#my $test = $vmw->login({
#	username => 'username',
#	password => 'password'
#});
#print Dumper($test);

sub new {
	my $self = {};
	my $class = shift;
	return bless($self, $class);
}

sub login {
	my $self = shift;
	my $auth = shift;

	# set up UA
	my $cookie_jar = HTTP::Cookies->new(
		file => "cookies.dat",
		autosave => 1,
	);
	my $ua = LWP::UserAgent->new(
		'cookie_jar' => $cookie_jar
	);
	$ua->timeout(10);
	$ua->env_proxy;
	$ua->show_progress(0);
	$ua->add_handler(response_header => sub {
		my($response, $ua, $h) = @_;
		if($response->header('location') =~ m/AUTH-ERR-20001/) {
			print("ERROR: Invalid Username or Password, please check credentials in config.json, or run 'myvmw help' for help\n");
		}
	});
	push(@{$ua->requests_redirectable}, 'POST'); # support 302 for POST

	# req01
	$ua->default_header(
		#'upgrade-insecure-requests' => "1",
		'user-agent' => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36",
		#'accept' => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
		#'dnt' => "1",
		#'accept-encoding' => "gzip, deflate, br",
		#'accept-language' => "en-GB,en-US;q=0.8,en;q=0.6",
		'cache-control' => "no-cache"
	);

	my $response = $ua->get('https://my.vmware.com');	
	if ($response->is_success) {
	} else {
		die $response->status_line;
	}
	
	# req02
	# work out how to encode credentials
	my $uri = URI::Encode->new({ encode_reserved => 1 });
	my $body = 'password='.$uri->encode($auth->{password}).'&username='.$uri->encode($auth->{username}).'&vmware=login';
	my $response = $ua->post('https://my.vmware.com/oam/server/auth_cred_submit',
		'Content'	=> $body
	);
	if ($response->is_success) {
		#print Dumper($response->decoded_content);
	} else {
		die($response->status_line."\n");
	}

	return $ua;
}

1;
