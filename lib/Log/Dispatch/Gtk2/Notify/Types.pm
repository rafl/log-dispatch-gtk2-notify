package Log::Dispatch::Gtk2::Notify::Types;

use MooseX::Types::Moose qw/Str/;
use Log::Dispatch;

use namespace::clean -except => 'meta';

use MooseX::Types -declare => [qw/
    LogLevel
    Widget
    StatusIcon
    Pixbuf
/];

subtype LogLevel,
    as Str,
    where { Log::Dispatch->level_is_valid($_) },
    message { 'invalid log level' };

class_type Widget,     { class => 'Gtk2::Widget'      };
class_type StatusIcon, { class => 'Gtk2::StatusIcon'  };
class_type Pixbuf,     { class => 'Gtk2::Gdk::Pixbuf' };

1;
