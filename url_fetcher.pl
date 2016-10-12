#!/usr/bin/perl -w
use strict;
use warnings;
use feature 'say';
use open qw/:std :utf8/;

use AnyEvent;
use EV;
use AnyEvent::HTTP;

use DDP;

### Скрипт нужно запускать:
# cat urls.txt | ./url_fetcher.pl

my @reqs_time;
my $cv = AnyEvent->condvar;
$cv->begin;
while (<>) {
    chomp;
    $cv->begin;
    my $req_time = AnyEvent->time;
    http_get $_, sub {
        my ($content, $headers) = @_;
        my $completed = AnyEvent->time;
        my $req_time  = format_seconds( $completed - $req_time );
        # print "Got answer in $req_time seconds\n";
        push @reqs_time, [$headers->{URL}, $req_time];

        if ($headers->{Status} =~ /^2/) {
            say "$headers->{URL}, status: $headers->{Status}, req_time: $req_time sec";
        } else {
            say "error, $headers->{Status} $headers->{Reason}";
        }

        $cv->end;
    };
}
$cv->end;
$cv->recv;

for (@reqs_time) {
    say "url: $_->[0], request time: $_->[1] sec";
}

sub format_time {
    my ( $microsec, $seconds ) = modf(shift);

    my ( $sec, $min, $hour ) = localtime($seconds);

    return sprintf "%02d:%02d:%02d.%04d", $hour, $min, $sec, int( $microsec * 10000 );
}

sub format_seconds {
    return sprintf "%.4f", shift;
}
