package RFID::Alien::Tag;
use RFID::Alien::Reader; $VERSION=$RFID::Alien::Reader::VERSION;

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

=head1 NAME

RFID::Alien::Tag - Object representing a single tag read by an Alien reader.

=head1 SYNOPSIS

These objects are usually returned by an
L<RFID::Alien::Reader|RFID::Alien::Reader> object:

    use RFID::Alien::Tag;

    my $reader = 
      RFID::Alien::Reader::TCP->new(PeerAddr => 'alien1.example.com',
	 		            PeerPort => 4001,
				    )
        or die "Couldn't create reader object";

    my @tags = RFID::Alien::Reader->new->readtags();
    foreach my $tag (@tags)
    {
	print "I see tag ",$tag->id,"\n";
    }

But you can create your own if you want:

    my $tag = RFID::Alien::Tag->new(id => '8000800433065081');
    print "Tag is ",$tag->id,"\n";

=head1 DESCRIPTION

=cut

use strict;

our(@ISA,@EXPORT_OK,%EXPORT_TAGS);
@ISA=qw(Exporter);
@EXPORT_OK=qw(tagcmp);

=head2 Constructor

=head3 new

Creates a new I<RFID::Alien::Tag> object.  Taks a hash containing
various settings as its parameters.  There is currently only one
required setting, C<id>, which should contain a string of hex digits
representing the ID of the tag.  An optional setting is C<ant>, which
specifies the antenna this tag was read from.

=cut

sub new {
    my $class = shift; 
    my $self = {};

    my(%p) = @_;
    if ($p{id})
    {
	($self->{id} = uc $p{id}) =~ s/[^0-9A-F]//g;
    }
    if (defined($p{ant}))
    {
	$self->{ant} = $p{ant};
    }

    bless $self,$class;
}

=head2 Methods

=head3 id

Returns a text representation of the tag's ID number.

=cut

sub id
{
    my $self = shift;
    return $self->{id};
}

=head3 ant

Returns a text representation of the antenna this tag was read from,
if available.

=cut

sub ant
{
    my $self = shift;
    return $self->{ant};
}

=head2 Utility Functions

=head3 tagcmp

A comparison function for C<sort>.  Compares the ID numbers of two
tags, and returns -1 if the first ID is lower, 0 if they are the same,
or 1 if the first ID is higher.

=cut

sub tagcmp($$)
{
    return $_[0]->{id} cmp $_[1]->{id};
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
