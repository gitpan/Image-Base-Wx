#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

# This file is part of Image-Base-Wx.
#
# Image-Base-Wx is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Wx is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Wx.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use Wx;

# uncomment this to run the ### lines
use Smart::Comments;

{
  # read png
  Wx::InitAllImageHandlers();
  require Image::Base::Wx::Bitmap;
  my $image = Image::Base::Wx::Bitmap->new
    (-file => '/usr/share/doc/wx2.8-examples/examples/samples/dnd/wxwin.png');
  ### $image
  exit 0;
}
{
  # transparent
  Wx::InitAllImageHandlers();
  require Image::Base::Wx::Bitmap;
  { my $image = Image::Base::Wx::Bitmap->new
      (-width  => 20,
       -height => 10,
       -file_format => 'png');
    ### $image

    my $wxbitmap = $image->get('-wxbitmap');
    $wxbitmap->InitAlpha;
    ### HasAlpha: $wxbitmap->HasAlpha

    $image->rectangle (5,5, 10,8, 'none', 1);
    $image->rectangle (19,9, 19,9, 'None', 1);
    $image->rectangle (6,6, 7,7, 'green', 1);
    $image->save('/tmp/x.png');
    system ('convert /tmp/x.png /tmp/x.xpm');
    system ('cat /tmp/x.xpm');
  }
  exit 0;
}
