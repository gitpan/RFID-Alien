#!/usr/bin/perl -w

use strict;

use Getopt::Std;
use RFID::Alien::Reader;

use constant TAG_TIMEOUT => 10;
use constant CMD_TIMEOUT => 15;
use constant POLL_TIME => 5;
use constant DEFAULT_NAME => 'alien';

our %opt;
BEGIN {
    getopts("h:c:l:n:a:d",\%opt)
	or die "Usage: $0 [-cd]\n";
    if ($opt{c} and $^O eq 'MSWin32')
    {
	eval '
              use Win32::Serialport;
              use RFID::Alien::Reader::Serial;
        ';
    }
    elsif ($opt{h})
    {
	eval 'use RFID::Alien::Reader::TCP;';
    }
}

our($debug, $name, @ant, $login, $password);
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
    $com = Win32::SerialPort->new($opt{c})
	or die "Couldn't open COM port '$opt{c}': $^E\n";
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

my $ver = $reader->get('ReaderVersionString');
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
	print "ISEE alien.",$tag->id," FROM $name.",$tag->ant," AT $now TIMEOUT ",TAG_TIMEOUT,"\n";
    }
    sleep(POLL_TIME);
}
