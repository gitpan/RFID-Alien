package RFID::Alien::Reader::TCP;
use RFID::Alien::Reader; $VERSION=$RFID::Alien::Reader::VERSION;
@ISA = qw(RFID::Alien::Reader);

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

=head1 NAME

RFID::Alien::Reader::TCP - Implement L<RFID::Alien::Reader|RFID::Alien::Reader> over a TCP connection

=head1 SYNOPSIS

This class takes a host and port to connect to, connects to it, and
implements the Alien RFID protocol over that connection.  It can use
the reader's builting TCP service, or a serial-to-Ethernet adapter
plugged into the serial port of the reader; I tested it with both.

=head1 DESCRIPTION

This class is built on top of
L<RFID::Alien::Reader|RFID::Alien::Reader> and
L<IO::Socket::INET>, and implements the underlying setup, reading, and
writing functions.

Currently, the I<Timeout> parameter isn't handled properly for
commands (but it is for initiating the connection).

=cut

use IO::Socket::INET;
use IO::Select;

=head2 Constructor

=head3 new

This constructor accepts all arguments to the constructor for
L<IO::Socket::INET|IO::Socket::INET>, and passes them along to both
constructors.  Any other settings are intrepeted as parameters to the
L<set|RFID::Alien::Reader/set> method.

=cut

sub new
{
    my $class = shift;
    my(%p)=@_;
    
    my $self = {};

    # For IO::Socket::INET
    if ($p{timeout} && !$p{Timeout})
    {
	$p{Timeout}=$p{timeout};
    }

    $self->{_sock}=IO::Socket::INET->new(%p)
	or die "Couldn't create socket: $!\n";
    $self->{_select}=IO::Select->new($self->{_sock})
	or die "Couldn't create IO::Select: $!\n";
    bless $self,$class;

    $self->_init(%p);

    $self;
}

sub _readbytes
{
    my $self = shift;
    my($bytesleft)=@_;
    my $data = "";

    while($bytesleft > 0)
    {
	my $moredata;
	if ($self->{timeout})
	{
	    $self->{_select}->can_read($self->{timeout})
		or die "Read timed out.\n";
	}
	my $rb = $self->{_sock}->read($moredata,$bytesleft)
	    or die "Socket unexpectedly closed!\n";
	$bytesleft -= $rb;
	$data .= $moredata;
    }
    $data;
}

sub _readuntil
{
    my $self = shift;
    my($delim) = @_;

    local $/ = $delim;
    my $fh = $self->{_sock};
    defined(my $data = <$fh>)
	or die "Couldn't read from socket: $!\n";
    chomp($data);
    $data;
}

sub _writebytes
{
    my $self = shift;
    if ($self->{timeout})
    {
	$self->{_select}->can_write($self->{timeout})
	    or die "Write timed out.\n";
    }
    $self->{_sock}->syswrite(@_);
}

sub _connected
{
    return $self->{_sock};
}

=head1 SEE ALSO

L<RFID::Alien::Reader>, L<RFID::Alien::Reader::Serial>,
L<IO::Socket::INET>.

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2004 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.

1;
