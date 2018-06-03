#!/usr/bin/perl
use Data::Dumper;
use lib '/root/';
use vmwLogin;
use vmwIndex;
use vmwProduct;
use vmwDownload;
use JSON::PP;
use Cwd;
use xview;
select( ( select(\*STDERR), $|=1 )[0] );
select( ( select(\*STDOUT), $|=1 )[0] );

my $find = $ARGV[0];
if($find eq 'help') { # change to switch
	help();
} else {
	start($find);
}

sub start {
	my $find = shift;
	# read in JSON config
	my $dir = '/vmwfiles/';
	my $filename = $dir.'config.json';
	my $json = JSON::PP->new->ascii->pretty->allow_nonref;
	my $jsondata;
	if(open(my $json_file, '<', $filename)) {
	        local $/;
	        $jsondata = <$json_file>;
	        close($json_file);
	} else {
		help();
		die("ERROR: Download directory or config.json file missing!\n");
	}
	my $config = $json->decode($jsondata);
	
	#login
	print("Realigning inertial dampeners for: https://my.vmware.com\n");
	sleep(1);
	print("Commencing molecular convergence of transient loop systems...\n"); # add a spinny thingy
	my $login = vmwLogin->new();
	my $ua = $login->login({
		username => $config->{username},
		password => $config->{password}
	});
	
	#build and write index
	print("Building product index\n");
	my $vmwidx = vmwIndex->new();
	my $index = $vmwidx->build($ua);
	
	# filter, build and write product
	#my $filter = "VMware vSAN";
	#my $filter = "VMware vSphere";
	#my $filter = "VMware NSX";
	if($find) {
		# build product list
		print("Reversing shield polarity for: ".$find."\n");
		my $product = vmwProduct->new();
		$product->find($ua, $find);
		
		#build download list
		my $download = vmwDownload->new();
		$download->build($ua);
	} else {
		#display summary
		my $cols = [
			'name',
		        'link'
		];
		my $view = xview->new($cols,  $index);
		$view->out();
	}
}

sub help {
	my $message = <<'SETUP';
#NOTE:
#-- Shell installation is OPTIONAL - if you prefer to use native docker commands you may also use the syntax at the end of this help

### myvmw CLI client BASH/ZSH installation process ###
#1) Install myvmw CLI client - issue the commands below in a new terminal window
#-- This will download the container from my public dockerhub account and run it
#-- Re-run these install steps at any time if you wish to change credentials or download directory
#-- Default download directory is ~/vmwfiles and the install will create a credentials file called ~/vmwfiles/config.json
#-- Only BASH or ZSH terminals currently supported for SHELL installation

# delete any old containers
docker rmi -f docker.io/apnex/myvmw

# create and run the myvmw installer (follow prompts)
docker run apnex/myvmw install > install.sh
chmod 755 install.sh
./install.sh

# close all terminal windows

#2) Open new terminal and run the myvmw client:
myvmw
# This will log in to my.vmware.com and list the available product categories

## myvmw CLI client command syntax
# view this help again
myvmw help

# view all product categories
myvmw

# view files in a category (note use of double-quotes)
myvmw "<category>"

# download a file (you'll need permissions on my.vmware to do this, as shown by a 'yes' in the 'download' column)
myvmw get <filename>

### myvmw CLI client command examples ###
# index/view all product categories
myvmw

# view files under "VMware NSX-T" category
myvmw "VMware NSX-T"

# download NSX-T Manager - Dropkick OVA
myvmw get nsx-unified-appliance-2.0.0.0.0.6522097.ova

### Manually running the docker container (no SHELL integration) ###
#1) Create a new empty local directory, ie 'mkdir vmwfiles' - this will be used for file downloads
#2) Create a new file 'config.json' in 'vmwfiles' directory above with the following structure (replace credentials with your own):
{
	"username": "username@domain.com",
	"password": "password"
}
#3) Run the docker container while mounting the local vmwfiles dir into the container as /vmwfiles
docker run --net host -v <LOCALVMWDIR>:/vmwfiles apnex/myvmw
SETUP
	print($message);
}
