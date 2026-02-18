#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use File::Path qw(make_path);
use File::Spec;
use POSIX qw(strftime);

# Configuration
my $log_base_dir = $ENV{LOG_DIR} || '/logs';
my $flush_delay = ($ENV{FLUSH_DELAY_MS} || 300) / 1000;  # Convert ms to seconds
my $current_fh;
my $current_path = '';
my $flush_timer;

get '/' => sub ($c) {
    my $remote_ip = $c->tx->remote_address;
    app->log->info("/ from $remote_ip");
    
    $c->render(json => {ok => 1, remote_ip => $remote_ip});
};

# POST endpoint: / (body is JSON string or object)
post '/' => sub ($c) {
    my $stream = $c->param('stream') || 'Idvoyages';
    # validate: only word chars and hyphens
    unless ($stream =~ /^\w[\w\-]{0,40}$/ && $stream =~ /^\w+-\w+$/) {
        return $c->render(json => {error => 'bad stream'}, status => 400);
    }

    my $data = $c->req->body;
    unless ($data) {
        return $c->render(json => {error => 'Missing data'}, status => 400);
    }
    
    # Get current log file path
    my $path = get_log_filepath($stream);
    
    # Reopen if path changed
    if ($path ne $current_path) {
        # Flush and close old handle
        if ($current_fh) {
            $current_fh->flush();
            close $current_fh;
        }
        
        # Cancel pending flush timer
        Mojo::IOLoop->remove($flush_timer) if $flush_timer;
        $flush_timer = undef;
        
        # Ensure directory exists
        my ($vol, $dirs, $file) = File::Spec->splitpath($path);
        my $dir = File::Spec->catpath($vol, $dirs, '');
        make_path($dir) unless -d $dir;
        
        # Open new file handle
        open $current_fh, '>>', $path or die "Can't open $path: $!";
        $current_path = $path;
    }
    
    # Write the data
    print $current_fh $data, "\n";
    unless ($flush_timer) {
        $flush_timer = Mojo::IOLoop->timer($flush_delay => sub {
            $current_fh->flush() if $current_fh;
            $flush_timer = undef;
        });
    }

    my $remote_ip = $c->tx->remote_address;
    # < remove this after verifying not public
    app->log->info("/ post from $remote_ip");
    
    $c->render(json => {ok => 1});
};

# Get log file path: /logs/Tyrant-Idvoyages/Idvoyages-YYYYMMDD/HHMM.jsons
sub get_log_filepath {
    my ($stream) = @_;
    my ($category,$section) = split '-', $stream;
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time);
    $year += 1900;
    $mon += 1;
    $min = $min - $min % 20;
    
    my $dir_name = sprintf("$section-%04d%02d%02d", $year, $mon, $mday);
    my $filename = sprintf("%02d%02d.jsons", $hour, $min);
    
    return File::Spec->catfile(
        $log_base_dir, 
        $stream, 
        $dir_name, 
        $filename
    );
}

# Cleanup on exit
END {
        $current_fh->flush()if $current_fh;;
    close $current_fh if $current_fh;
}

app->start;