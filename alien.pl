#!/usr/bin/perl -w

use strict;

use Getopt::Std;
use RFID::Alien::Reader;
use RFID::Alien::Reader::Serial;
use RFID::Alien::Reader::TCP;

BEGIN {
    # Try to load these; if they fail we'll detect it later.
    # Doing it outside of a BEGIN block makes Win32::SerialPort spew
    # errors.
    eval 'use Win32::SerialPort';
    eval 'use Device::SerialPort';
}

use constant TAG_TIMEOUT => 10;
use constant CMD_TIMEOUT => 15;
use constant POLL_TIME => 0;
use constant DEFAULT_NAME => 'alien';

our %opt;
getopts("h:c:l:n:a:p:d",\%opt)
    or die "Usage: $0 [-cd]\n";

our($debug, $name, @ant, $login, $password, $polltime);
$debug=$opt{d}||$ENV{ALIEN_DEBUG};
$name=$opt{n}||DEFAULT_NAME;
if ($opt{a})
{
    @ant = (split(/,/,$opt{a}));
}
else
{
    @ant = (0);
}
$polltime=defined($opt{p})?$opt{p}:POLL_TIME;

if ($opt{l})
{
    open(LOGIN,"< $opt{l}")
	or die "Couldn't open login information file '$opt{l}': $!\n";
    chomp($login=<LOGIN>);
    chomp($password=<LOGIN>);
    close(LOGIN)
	or die "Couldn't close login information file '$opt{l}': $!\n";
}

$| = 1;

our($com,$reader);

END {
    if ($com)
    {
	$com->purge_all();
    }
    if ($reader)
    {
	$reader->finish()
	    or warn "Couldn't stop constant read: $!\n";
    }
    if ($com)
    {
	$com->close()
	    or warn "Couldn't close COM port: $!\n";
    }
}

# Uncaught signals don't call END blocks.
for my $sig (grep { exists $SIG{$_} } qw(INT TERM BREAK HUP))
{
    $SIG{$sig} = sub { exit(1); };
}

if ($opt{c})
{
    if ($INC{'Win32/SerialPort.pm'})
    {
	$com = Win32::SerialPort->new($opt{c})
	        or die "Couldn't open COM port '$opt{c}': $^E\n";
    }
    elsif ($INC{'Device/SerialPort.pm'})
    {
	$com = Device::SerialPort->new($opt{c})
	        or die "Couldn't open COM device '$opt{c}'!\n";
    }
    else
    {
	die "Couldn't find either Win32::SerialPort or Device::SerialPort!\n";
    }
    $reader = RFID::Alien::Reader::Serial->new(Port => $com,
					       Debug => $debug,
					       Timeout => CMD_TIMEOUT,
					       )
	or die "Couldn't create RFID reader object: $!\n";
}
elsif ($opt{h})
{
    my($addr,$port);
    if ($opt{h} =~ /^([\w.-]+):(\d+)$/)
    {
	($addr,$port)=($1,$2);
    }
    else
    {
	$addr = $opt{h};
	$port = 4001;
    }
    
    $reader = RFID::Alien::Reader::TCP->new(PeerAddr => $addr,
					    PeerPort => $port,
					    Debug => $debug,
					    Timeout => CMD_TIMEOUT,
					    Login => $login,
					    Password => $password,
					    )
	or die "Couldn't create RFID reader object: $!\n";
}
else
{
    die "Must specify -c comport or -h hostname:port\n";
}

my $ver = $reader->get('ReaderVersion');
print "Reader version: $ver";

$reader->set(PersistTime => 0) == 0
    or die "Couldn't set PersistTime to 0!\n";
$reader->set(AcquireMode => 'Inventory') == 0
    or die "Couldn't set AcquireMode to Global Scroll!\n";
$reader->set(AntennaSequence => \@ant) == 0
    or die "Couldn't set antenna sequence!\n";
$reader->set(TagListAntennaCombine => 'OFF') == 0
    or die "Couldn't set TagListAntennaCombine!\n";

# Now start polling
while(1)
{
    print "Scanning for tags\n";
    my @pp = $reader->readtags();
    my $now = time
	if (@pp);
    foreach my $tag (@pp)
    {
	my %ti = $tag->get('ID','Type','Antenna');
	$ti{epc_type}||='none';
	print "ISEE $ti{Type}.$ti{ID} FROM $name.$ti{Antenna} AT $now TIMEOUT ",TAG_TIMEOUT,"\n";
    }
    sleep($polltime);
}
