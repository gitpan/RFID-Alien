#!/usr/bin/perl -w

use strict;

use Test::More tests => 45;
use RFID::Alien::Reader::Test;
use RFID::Alien::Tag qw(tagcmp);

my $obj = RFID::Alien::Reader::Test->new(node => 4,
					 debug => $ENV{ALIEN_DEBUG},
					 );
isa_ok($obj,'RFID::Alien::Reader::Test');
isa_ok($obj,'RFID::Alien::Reader');
ok($obj->get('ReaderVersionString'));

use constant TAGID => '8000800433065081';

my $tag = RFID::Alien::Tag->new(id => TAGID);
isa_ok($tag,'RFID::Alien::Tag');
ok(tagcmp($tag,$tag)==0);

# Read some tags.  Mock Antenna 0 has tags; the others don't.
ok($obj->set(AntennaSequence => [0]) == 0);
ok(($obj->get('AntennaSequence'))->[0] eq '0'
   and !defined(($obj->get('AntennaSequence'))->[1]));
my @readtags = $obj->readtags();
ok(@readtags == 2);
isa_ok($readtags[0],'RFID::Alien::Tag');
isa_ok($readtags[1],'RFID::Alien::Tag');
ok(tagcmp($readtags[0],$tag)==0);

ok($obj->set(AntennaSequence => [1,0]) == 0);
ok(($obj->get('AntennaSequence'))->[0] eq '1' 
   and ($obj->get('AntennaSequence'))->[1] eq '0'
   and !defined(($obj->get('AntennaSequence'))[2]));
@readtags = $obj->readtags();
ok(@readtags == 2);
isa_ok($readtags[0],'RFID::Alien::Tag');
isa_ok($readtags[1],'RFID::Alien::Tag');
ok(tagcmp($readtags[0],$tag)==0);

ok($obj->set(AntennaSequence => [1]) == 0);
ok(($obj->get('AntennaSequence'))->[0] eq '1' 
   and !defined(($obj->get('AntennaSequence'))->[1]));
@readtags = $obj->readtags();
ok(@readtags == 0);

# Set some simple variables
ok($obj->set(PersistTime => 600) == 0);
ok($obj->set(AcquireMode => 'Global Scroll') == 0);
ok($obj->get('PERSISTTIME') eq '600');
ok($obj->get('ACQUIREMODE') eq 'Global Scroll');
ok($obj->set(PERSISTTIME => 100,
	     acquiremode => 'Imaginary') == 0);
my %v = $obj->get(qw(AcQuIrEmODe PErsISttIMe));
ok(%v);
ok($v{PErsISttIMe} eq '100');
ok($v{AcQuIrEmODe} eq 'Imaginary');

# Now set some more complex variables.
my $testtime = time - 86400;
ok($obj->set(Time => $testtime) == 0);
ok($obj->get('Time') == $testtime);
ok($obj->set(Time => '') == 0);
ok(abs($obj->get('Time') - time) < 3600);

ok($obj->get('Mask') eq '');
ok($obj->set(Mask => TAGID) == 0);
ok($obj->get('Mask') eq TAGID.'/64');
ok($obj->set(Mask => '80008/20') == 0);
ok($obj->get('Mask') eq '800080/20');
ok($obj->set(Mask => '800080/20/16') == 0);
ok($obj->get('Mask') eq '800080/20/16');
ok($obj->set(Mask => '') == 0);
ok($obj->get('Mask') eq '');

my $ver = $obj->get('ReaderVersion');
ok($ver);
isa_ok($ver,'HASH');
ok($ver->{reader_type} and $ver->{reader_type} eq 'RFID-Alien-Reader-Test');
ok($ver->{software} and $ver->{software} eq $RFID::Alien::Reader::VERSION);

1;
