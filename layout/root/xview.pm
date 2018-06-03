#!/usr/bin/perl
package xview;

=begin ## test client
my $cols = [
	'name',
	'place'
];
my $data = [
	{
		name => 'john333',
		place => 'moo01'
	},
	{
		name => 'john',
		place => 'moo02123'
	},
	{
		name => 'michael',
		place => 'anothermoo02123'
	},
	{
		name => 'john',
		place => 'moo03'
	}
];
my $client = xview->new($cols, $data);
$client->out();
=end
=cut

sub new {
       	my $class = shift;
	my $cols = shift;
	my $data = shift;
	my $self = {
		cols => $cols,
		data => $data,
		align => '<',
		cache => {}
	};
	return bless($self, $class);
}

sub out {
	my $self = shift;
	my $cols = $self->{cols};
	my $data = $self->{data};

	# set width to header width
	foreach(@{$cols}) {
		$self->{cache}->{$_} = length($_);
	}
	# scan cols for max width
	foreach my $item(@{$data}) {
		$self->runColWidth($item);
	}
	
	my $format = $self->execFormat($cols, $data);
	eval $format;
	#print($format);

	$~ = HEADER;
	write;
	$~ = RECORD;	
	my $ii;
	foreach $item(@{$data}) {
		write;
		$ii++;
	}
	print("## ".$ii." items\n");
}

sub runColWidth {
	my $self = shift;
	my $item = shift;
	my $cache = $self->{cache};

	# go through record and cache each width
	foreach my $col(keys(%{$item})) {
		if($cache->{$col} < length($item->{$col})) {
			$cache->{$col} = length($item->{$col});
		}
	}
}

sub execFormat {
	my $self = shift;
	my $columns = shift;
	my $data = shift;

	my $space = " ";
	my $format = "format HEADER = \n";
	foreach my $id(@{$columns}) {
		$format .= $id.($space x ($self->{cache}->{$id} - length($id)))."  ";
        }
	$format .= "\n";

	my $dash = "-";
	foreach $id(@{$columns}) {
		$format .=  $dash x $self->{cache}->{$id}."  ";
        }

	$format .= "\n.\n";
	$format .= "format RECORD = \n";
	foreach $id(@{$columns}) {
		$format .= $self->execCol($id)."  ";
	}
	$format .= "\n";

	foreach $id(@{$columns}) {
		$format .= '$item->{"'.$id.'"}, ';
	}
	$format .= "\n.\n";

	return $format;
}

sub execCol {
	my $self = shift;
	my $col = shift;

	$colformat = '@'.$self->{align} x ($self->{cache}->{$col} - 1);
	return $colformat;
}

1;

