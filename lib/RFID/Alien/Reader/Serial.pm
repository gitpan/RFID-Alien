package RFID::Alien::Reader::Serial;
use RFID::Alien::Reader; $VERSION=$RFID::Alien::Reader::VERSION;
@ISA = qw(RFID::Alien::Reader);

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

=head1 NAME

RFID::Alien::Reader::Serial - Implement L<RFID::Alien::Reader|RFID::Alien::Reader> over a serial link

=head1 SYNOPSIS

This class takes a serial port object and implements the Alien RFID
protocol over it.  The serial port object should be compatible with
L<Win32::SerialPort|Win32::SerialPort>; the Unix equivalent is
L<Device::SerialPort|Device::SerialPort>.  You are responsible for
creating the serial port object.

An example:

    use Win32::Serialport;
    use RFID::Alien::Reader::Serial;

    $com = Win32::SerialPort->new('COM1')
	or die "Couldn't open COM port 'COM1': $^E\n";

    my $reader = 
      RFID::Alien::Reader::Serial->new(Port => $com,
				       AntennaSequence => [0,1,2,3])
        or die "Couldn't create reader object\n";

    $reader->set(PersistTime => 0,
                 AcquireMode => 'Inventory') == 0
        or die "Couldn't set reader properties\n";

    my @tags = $reader->readtags();
    foreach my $tag (@tags)
    {
	print "I see tag ",$tag->id,"\n";
    }

=head1 DESCRIPTION

This class is built on top of
L<RFID::Alien::Reader|RFID::Alien::Reader>, and implements the
underlying setup, reading, and writing functions.

=cut

use constant BAUDRATE => 115200;
use constant DATABITS => 8;
use constant STOPBITS => 1;
use constant PARITY => 'none';
use constant HANDSHAKE => 'none';
use constant DEFAULT_TIMEOUT => 2000; #ms
use constant STREAMLINE_TIMEOUT => 50; #ms

=head2 Constructor

=head3 new

Creates a new object.  It takes the following parameters:

=over 4

=item Port

Required parameter.  A
L<Win32::SerialPort|Win32::SerialPort>-compatible object over which
the serial communication should take place.

=item Baud

Optional parameter.  The baud rate at which we should communicate over
the serial port.  The default is 115200, which is the default speed of
the Alien reader.

=back

Any other parameters will be passed to the object's
L<set|RFID::Alien::Reader/set> method.  In the event of an error, this
constructor will C<die> with an appropriate error message; you can
catch this in an C<eval> block..

=cut

sub new
{
    my $class = shift;
    my(%p)=@_;
    
    my $self = {};

    $self->{com} = $p{Port}
        or die "Alien::Reader::new requires argument 'com'\n";
    delete $p{Port};

    $self->{com}->databits(DATABITS);
    $self->{com}->stopbits(STOPBITS);
    $self->{com}->parity(PARITY);
    $self->{com}->handshake(HANDSHAKE);

    my $baudrate = $p{Baud}||BAUDRATE;
    if ($baudrate > 115200 && (ref($self->{com}) eq 'Win32::SerialPort'))
    {
	# This is a hack to work around an annoying bug in Win32::CommPort.
	$self->{com}->baudrate(115200);
	$self->{com}->{_N_BAUD}=$baudrate;
    }
    else
    {
	$self->{com}->baudrate($baudrate);
    }

    $self->{com}->write_settings 
	or die "No settings: $!\n";

    bless $self,$class;
    
    $self->{timeout} = DEFAULT_TIMEOUT;
    
    # Now clear out any data waiting on the serial port.
    $self->{com}->purge_all;
    $self->_writebytes("\x0d\x0a");
    my($rb,$data);
    do
    {
	$self->{com}->read_const_time(250);
	($rb,$data)=$self->{com}->read(4096);
	$self->_debug("Discarding $rb bytes of junk data: '$data'\n");
    } while ($rb);
    $self->{com}->purge_all;

    $self->_init(%p);
}

sub _writebytes
{
    my $self = shift;
    my($data)=@_;

    my $bytesleft = length($data);
    $self->{com}->write_const_time($self->{timeout});
    my $start = time;
    while ($bytesleft > 0)
    {
	if ( (time - $start) > $self->{timeout})
	{
	    die "Write timeout.\n";
	}
	my $wb = $self->{com}->write($data);
	substr($data,0,$wb,"");
	$bytesleft -= $wb;
    }
    1;
}

sub _connected
{
    return $self->{com};
}

sub _readuntil
{
    my $self = shift;
    my($delim) = @_;

    my $com = $self->{com};

    my $match;
    my $i = 0;
    $self->{com}->are_match($delim);
    while (!($match = $com->streamline(STREAMLINE_TIMEOUT)))
    {
	;
    }
    return $match;
}


=head1 SEE ALSO

L<RFID::Alien::Reader>.

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2004 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.

=cut



1;
