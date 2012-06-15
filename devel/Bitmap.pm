# Copyright 2012 Kevin Ryde

# This file is part of Image-Base-Wx.
#
# Image-Base-Wx is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Wx is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Wx.  If not, see <http://www.gnu.org/licenses/>.


package Image::Base::Wx::Bitmap;
use 5.004;
use strict;
use Carp;
use Wx;

use vars '$VERSION','@ISA';
$VERSION = 1;

use Image::Base::Wx::DC;
@ISA = ('Image::Base::Wx::DC');

# uncomment this to run the ### lines
use Smart::Comments;


sub new {
  my ($class_or_self, %params) = @_;
  ### Image-Base-Wx-Bitmap new: @_

  my $filename = delete $params{'-file'};
  my $wxbitmap = delete $params{'-wxbitmap'};
  my $dc = delete $params{'-dc'};

  my $class;
  if (ref $class_or_self) {
    # $obj->new(...) means make a copy, with some extra settings
    $class = ref $class_or_self;
    %params = (%$class_or_self, %params);
  } else {
    $class = $class_or_self;
  }

  if (ref $class_or_self) {
    # clone wxbitmap if a new one not given in the %params
    if (! defined $wxbitmap) {
      ### copy ...
      # maybe no copy-on-write constructor in 0.9901 ?
      $wxbitmap = $class_or_self->{'-wxbitmap'};
      ### $wxbitmap
      $wxbitmap = $wxbitmap->GetSubBitmap
        (Wx::Rect->new(0,0, $wxbitmap->GetWidth, $wxbitmap->GetHeight));
      ### copy: $wxbitmap
    }
  } else {
    if (! $wxbitmap) {
      ### new bitmap ...
      my $depth = $params{'-depth'};
      if (! defined $depth) { $depth = -1; }
      $wxbitmap = Wx::Bitmap->new
        (delete $params{'-width'}||1,
         delete $params{'-height'}||1,
         $depth);
    }
  }
  if (! defined $dc) {
    $dc = Wx::MemoryDC->new;
    $dc->SelectObject($wxbitmap);
    $dc->IsOk or croak "Oops, MemoryDC not IsOk()";
    ### new dc: $dc
  }
  my $self = $class->SUPER::new(%params,
                                -wxbitmap => $wxbitmap,
                                -dc => $dc);
  if (defined $filename) {
    $self->load($filename);
  }
  ### $self
  return $self;
}

my %attr_to_get_method
  = (-width  => 'GetWidth',
     -height => 'GetHeight',
     -depth  => 'GetDepth');
my %attr_to_option
  = (
     # -hotx   => Wx::wxbitmap_OPTION_CUR_HOTSPOT_X(),
     # -hoty   => Wx::wxbitmap_OPTION_CUR_HOTSPOT_Y(),
     # -quality_percent => 'quality',
    );
sub _get {
  my ($self, $key) = @_;

  if (my $method = $attr_to_get_method{$key}) {
    return $self->{'-wxbitmap'}->$method();
  }
  if (my $option = $attr_to_option{$key}) {
    return $self->{'-wxbitmap'}->GetOptionInt($option);
  }
  return $self->SUPER::_get($key);
}

# my %attr_to_set_method
#   = (-width  => 'SetWidth',
#      -height => 'SetHeight',
#      -depth  => 'SetDepth');
sub set {
  my ($self, %params) = @_;
  ### Image-Base-Wx-Bitmap set: \%params

  # -wxbitmap before applying -width,-height
  if (my $wxbitmap = delete $params{'-wxbitmap'}) {
    $self->{'-wxbitmap'} = $wxbitmap;
  }
  if (exists $params{'-width'} || exists $params{'-height'}) {
    croak "-width or -height are read-only";
    # my $wxbitmap = $self->{'-wxbitmap'};
    # my $width = (exists $params{'-width'}
    #              ? delete $params{'-width'}
    #              : $wxbitmap->GetWidth);
    # my $height = (exists $params{'-height'}
    #               ? delete $params{'-height'}
    #               : $wxbitmap->GetHeight);
    # $wxbitmap->Resize(Wx::Size->new($width,$height),
    #                  0,0,0); # fill with black
  }
  foreach my $key (keys %params) {
    if (my $option = $attr_to_option{$key}) {
      return $self->{'-wxbitmap'}->GetOptionInt($option);
    }
  }
  $self->SUPER::set(%params);
  ### set leaves: $self
}

#------------------------------------------------------------------------------
# load/save

# Note: must try CUR before ICO to pick up HotSpotX and HotSpotY
my @file_formats = (qw(BMP
                       GIF
                       JPEG
                       PCX
                       PNG
                       PNM
                       TIF
                       XPM
                       CUR
                       ICO
                       ANI));
my @bitmap_types = map { my $constant = "wxBITMAP_TYPE_$_";
                        my $type = eval "Wx::$constant()";
                        if (! defined $type) {
                          die "Oops, no $constant: $@";
                        }
                        $type } @file_formats;
### @bitmap_types

sub load {
  my ($self, $filename) = @_;
  if (@_ == 1) {
    $filename = $self->get('-file');
  } else {
    $self->set('-file', $filename);
  }
  ### load: $filename

  $filename = "$filename"; # stringize to dispatch to file read
  open my $fh, '<', $filename
    or croak "Cannot load $filename: $!";

  my $wxbitmap = $self->{'-wxbitmap'};
  foreach my $i (0 .. $#file_formats) {
    my $file_format = $file_formats[$i];
    my $type = $bitmap_types[$i];
    ### $file_format
    ### $type

    # my $handler = Wx::Bitmap::FindHandlerType($type) || next;
    # ### $handler
    # if ($handler->LoadFile ($wxbitmap, $fh)) {
    #   ### loaded ...
    #   ### wxbitmap isok: $wxbitmap->IsOk
    #   $self->{'-file_format'} = $file_format;
    #   return;
    # }

    if ($wxbitmap->LoadFile ($fh, $type)) {
      ### loaded ...
      ### wxbitmap isok: $wxbitmap->IsOk
      $self->{'-file_format'} = $file_format;
      return;
    }

    seek $fh,0,0 or croak "Cannot rewind $filename: $!";
  }
  croak "Cannot load ",$filename;

    # if ($wxbitmap->LoadFile($filename,$type)) {
    #   $self->{'-file_format'} = $type;
    #   return;
    # }
}

# sub load_fh {
#   my ($self, $fh, $filename) = @_;
#   ### load_fh()
# 
#   $self->{'-wxbitmap'}->LoadFile($fh,Wx::wxBITMAP_TYPE_ANY())
#     or croak "Cannot read file",
#       (defined $filename ? (' ',$filename) : ());
# }

sub save {
  my ($self, $filename) = @_;
  if (@_ == 2) {
    $self->set('-file', $filename);
  } else {
    $filename = $self->get('-file');
  }
  ### $filename

  my $file_format = $self->get('-file_format')
    || croak "-file_format not set";
  $file_format = lc($file_format);
  if ($file_format eq 'jpg') {
    $file_format = 'jpeg';
  }

  my $wxbitmap = $self->{'-wxbitmap'};
  foreach my $i (0 .. $#file_formats) {
    my $file_format = $file_formats[$i];
    my $type = $bitmap_types[$i];
    ### $file_format
    ### $type

    if ($wxbitmap->SaveFile($filename,$type)) {
      return;
    }
  }
  croak "Cannot load ",$filename;
}

# sub save_fh {
#   my ($self, $fh, $filename) = @_;
# 
#   my $file_format = $self->get('-file_format');
#   # if (! defined $file_format) {
#   #   $file_format = _filename_to_format($filename);
#   #   if (! defined $file_format) {
#   #     croak 'No -file_format set';
#   #   }
#   # }
# 
#   $self->{'-wxbitmap'}->SaveFile($fh, "image/$file_format")
#     or croak "Cannot save file",
#       (defined $filename ? (' ',$filename) : ());
# }

#------------------------------------------------------------------------------

1;
__END__

=for stopwords resized filename Ryde bitmap

=head1 NAME

Image::Base::Wx::Bitmap -- draw into a Wx::Bitmap

=for test_synopsis my $wxbitmap

=head1 SYNOPSIS

 use Image::Base::Wx::Bitmap;
 my $image = Image::Base::Wx::Bitmap->new
                 (-wxbitmap => $wxbitmap);
 $image->line (0,0, 99,99, '#FF00FF');
 $image->rectangle (10,10, 20,15, 'white');

=head1 CLASS HIERARCHY

C<Image::Base::Wx::Bitmap> is a subclass of C<Image::Base>,

    Image::Base
      Image::Base::Wx::DC
        Image::Base::Wx::Bitmap

=head1 DESCRIPTION

C<Image::Base::Wx::Bitmap> extends C<Image::Base> to draw into a
C<Wx::Bitmap>, including image file load and save to a C<Wx::Bitmap>.

C<Wx::Bitmap> is a platform-dependent colour image.  The bits-per-pixel
supported depend on the platform, but should include at least 1-bit
monochrome and the depth of the screen.

Drawing is done through a C<Wx::MemoryDC> as per C<Image::Base::Wx::DC>.

=head1 FUNCTIONS

See L<Image::Base/FUNCTIONS> for behaviour common to all Image-Base classes.

=over 4

=item C<$image = Image::Base::Wx::Bitmap-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.  It can read a file,

    $image = Image::Base::Wx::Bitmap->new
               (-file => '/my/file/name.bmp');

Or create a new bitmap with width and height.  The default C<-depth> is the
bits-per-pixel of the screen, or something else can be given.

    $image = Image::Base::Wx::Bitmap->new
                 (-width  => 200,
                  -height => 100);

Or it can be pointed at an existing C<Wx::Bitmap>,

    my $wxbitmap = Wx::Bitmap->new (200, 100);
    my $image = Image::Base::Wx::Bitmap->new
                 (-wxbitmap => $wxbitmap);

Further parameters are applied per C<set> (see L</ATTRIBUTES> below).

=back

=head1 ATTRIBUTES

=over

=item C<-wxbitmap> (C<Wx::Bitmap> object)

The target bitmap object.

=item C<-dc> (C<Wx::DC> object)

The C<Wx::DC> used to draw into the bitmap.  A suitable DC is created for
the bitmap automatically, but it can be set explicitly if desired.

=item C<-file_format> (string, default undef)

The file format from the last C<load()> and the format to use in C<save()>.
This is one of the C<wxBITMAP_TYPE_XXX> names such as "PNG" or "JPEG".

=item C<-width> (integer, read-only)

=item C<-height> (integer, read-only)

The size of the bitmap, per C<$wxbitmap-E<gt>GetWidth()> and
C<$wxbitmap-E<gt>GetHeight()>.  Currently these are read-only.  Can a bitmap
be resized dynamically?

=item C<-depth> (integer, read-only)

The number of bits per pixel in the bitmap, per
C<$wxbitmap-E<gt>GetDepth()>.  Currently this is read-only.  Can a bitmap be
reformatted dynamically?

=back

=head1 SEE ALSO

L<Image::Base>,
L<Wx>

=head1 HOME PAGE

http://user42.tuxfamily.org/image-base-wx/index.html

=head1 LICENSE

Copyright 2012 Kevin Ryde

Image-Base-Wx is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Image-Base-Wx is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Image-Base-Wx.  If not, see <http://www.gnu.org/licenses/>.

=cut
