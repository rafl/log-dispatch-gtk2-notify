package Log::Dispatch::Gtk2::Notify;
# ABSTRACT: send log messages to a desktop notification daemon

=head1 SYNOPSIS

    use Log::Dispatch::Gtk2::Notify;

    my $notify = Log::Dispatch::Gtk2::Notify->new(
        name      => 'notify',
        min_level => 'debug',
        app_name  => 'MyApp',
        title     => 'Important Message',
    );

    $notify->log(level => 'alert', message => 'Hello, World!');

=head1 DESCRIPTION

This modules allows you to send log messages to the desktop notification
daemon.

=cut

use Moose;
use MooseX::Types::Moose qw/Str HashRef ArrayRef CodeRef/;
use Log::Dispatch::Gtk2::Notify::Types qw/
    LogLevel
    Widget     is_Widget
    StatusIcon is_StatusIcon
    Pixbuf
/;
use File::Basename;
use Gtk2 -init;
use Gtk2::Notify;

use namespace::clean -except => 'meta';

extends qw/Moose::Object Log::Dispatch::Output/;

has title => (
    is      => 'ro',
    isa     => Str,
    default => sub { basename($0) },
);

has app_name => (
    is       => 'ro',
    isa      => Str,
    default  => __PACKAGE__,
);

has attach_to => (
    is  => 'ro',
    isa => Widget|StatusIcon,
    predicate => 'has_attach_to',
);

has icon_map => (
    is         => 'ro',
    isa        => HashRef[Pixbuf],
    lazy_build => 1,
);

has name => (
    isa      => Str,
    required => 1,
);

has min_level => (
    isa      => LogLevel,
    required => 1,
);

has max_level => (
    isa => LogLevel,
);

has callbacks => (
    isa => (ArrayRef[CodeRef]) | CodeRef,
);

=method new

Construct a new instance. Takes a hash containing the following parameters:

=over 4

=item name

=item min_level

=item max_level

=item callbacks

These are documented in L<Log::Dispatch::Output>.

=item title

The title shown in the notification window. Defaults to the programm name. This
parameter is required.

=item app_name

The application name Gtk2::Notify will be initialized with. Defaults to
C<Log::Dispatch::Gtk2::Notify>.

=item attach_to

A Gtk2::Widget or Gtk2::StatusIcon the notifications will be attached to.

=item icon_map

A hash ref of C<Gtk2::Gdk::Pixmap>s, mapping log levels to icons.

=back

=cut

around new => sub {
    my $orig = shift;
    my $class = shift;

    my $self = $class->$orig(@_);
    $self->_basic_init(@_);

    return $self;
};

sub BUILD {
    my ($self) = @_;
    Gtk2::Notify->init($self->app_name);
}

sub log_message {
    my ($self, %args) = @_;

    my $notification = Gtk2::Notify->new(
        $self->title, $args{message},
    );

    $self->_attach_notification($notification)
        if $self->has_attach_to;

    if (my $icon = $self->icon_map->{ $args{level} }) {
        $notification->set_icon_from_pixbuf($icon);
    }

    $notification->show;

    return;
}

sub _attach_notification {
    my ($self, $notification) = @_;
    my $to = $self->attach_to;

    if (is_StatusIcon($to)) {
        $notification->attach_to_status_icon($to);
    }
    elsif (is_Widget($to)) {
        $notification->attach_to_widget($to);
    }
    else {
        confess 'FAIL';
    }
}

sub _build_icon_map {
    my ($self) = @_;
    my $widget = Gtk2::Button->new;
    return {
        map {
            my $pixbuf = $widget->render_icon('gtk-dialog-' . $_->[0], 'dialog');
            (map { $_ => $pixbuf } @{ $_->[1] })
        } (['error'   => [qw/emergency alert critical error/]],
           ['warning' => [qw/warning/]],
           ['info'    => [qw/notice info debug/]]),
    };
}

__PACKAGE__->meta->make_immutable;

1;
