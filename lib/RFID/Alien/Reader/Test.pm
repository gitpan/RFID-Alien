package RFID::Alien::Reader::Test;
use RFID::Alien::Reader; $VERSION=$RFID::Alien::Reader::VERSION;
@ISA = qw(RFID::Alien::Reader);

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

=head1 NAME

RFID::Alien::Reader::Test - A fake implementation of L<RFID::Alien::Reader|RFID::Alien::Reader> for testing

=head1 SYNOPSIS

Provides fake backend methods to test out
L<RFID::Alien::Reader|RFID::Alien::Reader> without having access
to a real reader.

=cut

use Carp;

our %initval = (time => '',
		persisttime => '5',
		acquiremode => 'Inventory',
		taglistantennacombine => 'off',
		mask => 'All Tags',
		antennasequence => '0',
		readerversion => "Reader Type: RFID-Alien-Reader-Test, Ent. SW Rev: $VERSION",
		);
use constant TAGLIST => "Tag:8000 8004 3306 5081, CRC:CB1D, Disc:2004/06/09 11:01:43, Count:3, Ant:0\r\nTag:8000 8004 2812 6165, CRC:DA08, Disc:2004/06/09 11:01:43, Count:1, Ant:0";

sub new
{
    my $class = shift;
    my(%p) = @_;
    my $self = {};
    bless($self,$class);

    $self->_init(%p);
    $self->{_settings}={%initval};
    $self->{_readbuf}='';
    $self->{_writebuf}='';
    $self;
}

sub _writebytes
{
    my $self = shift;

    $self->{_readbuf} .= $_[0];
    while ($self->{_readbuf} =~ s/^\x01?([^\r\n]*)\r?\n//)
    {
	my ($cmd,$var,$rest) = split(' ',$1,3);
	if (lc $cmd eq 'get')
	{
	    if (lc $var eq 'taglist')
	    {
		if ($self->{_settings}{antennasequence} =~ /\b0\b/)
		{
		    $self->{_writebuf} .= TAGLIST."\x0d\x0a\0";
		}
		else
		{
		    $self->{_writebuf} .= "(No Tags)\x0d\x0a\0";
		}
	    }
	    elsif (lc $var eq 'readerversion')
	    {
		$self->{_writebuf} .= $self->{_settings}{lc $var}."\x0d\x0a\0";
	    }
	    else
	    {
		$self->{_writebuf} .= "$var = $self->{_settings}{lc $var}\x0d\x0a\0";
	    }
	}
	elsif (lc $cmd eq 'set')
	{
	    $rest =~ s/^\s*=\s*//
		or croak "Received invalid set command!";
	    $self->{_settings}{lc $var}=$rest;
	    $self->{_writebuf} .= "$var = $self->{_settings}{lc $var}\x0d\x0a\0";
	}
    }
    return length($_[0]);
}

sub _readuntil
{
    my $self = shift;

    if ($self->{_writebuf} =~ s/^([^\0]*)\0//)
    {
	return $1;
    }

    croak "Attempt to read with no data!";
}

=head1 SEE ALSO

L<RFID::Alien::Reader>, L<RFID::Alien::Reader::Serial>,
L<RFID::Alien::Reader::TCP>.

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2004 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.

=cut

1;
