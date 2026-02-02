#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use File::Path qw(make_path);
use File::Spec;
use POSIX qw(strftime);
use Time::HiRes qw(time);
use JSON::PP;

# Configuration
my $log_base_dir = $ENV{LOG_DIR} || '/logs';
my $flush_interval = 1; # seconds

# Storage for buffered logs per file
my %log_buffers;
my $last_flush = time();

# Auto-flush timer
Mojo::IOLoop->recurring($flush_interval => sub {
    flush_all_buffers();
});

# GET endpoint: /log?data=...
get '/log' => sub ($c) {
    my $data = $c->param('data');
    
    unless ($data) {
        return $c->render(json => {error => 'Missing data parameter'}, status => 400);
    }
    
    # Parse the data (expecting JSON)
    my $log_entry;
    eval {
        $log_entry = decode_json($data);
    };
    if ($@) {
        return $c->render(json => {error => "Invalid JSON: $@"}, status => 400);
    }
    
    # Get the log file path based on current time
    my ($filepath, $filename) = get_log_filepath();
    my $full_path = File::Spec->catfile($filepath, $filename);
    
    # Buffer the log entry
    push @{$log_buffers{$full_path}}, $log_entry;
    
    $c->render(json => {status => 'ok', buffered => scalar(@{$log_buffers{$full_path}})});
};

# POST endpoint: /log (body is JSON)
post '/log' => sub ($c) {
    my $log_entry = $c->req->json;
    
    unless ($log_entry) {
        return $c->render(json => {error => 'Missing or invalid JSON body'}, status => 400);
    }
    
    # Get the log file path based on current time
    my ($filepath, $filename) = get_log_filepath();
    my $full_path = File::Spec->catfile($filepath, $filename);
    
    # Buffer the log entry
    push @{$log_buffers{$full_path}}, $log_entry;
    
    $c->render(json => {status => 'ok', buffered => scalar(@{$log_buffers{$full_path}})});
};

# Batch POST endpoint: /log/batch (body is array of JSON objects)
post '/log/batch' => sub ($c) {
    my $log_entries = $c->req->json;
    
    unless ($log_entries && ref($log_entries) eq 'ARRAY') {
        return $c->render(json => {error => 'Body must be a JSON array'}, status => 400);
    }
    
    # Get the log file path based on current time
    my ($filepath, $filename) = get_log_filepath();
    my $full_path = File::Spec->catfile($filepath, $filename);
    
    # Buffer all log entries
    push @{$log_buffers{$full_path}}, @$log_entries;
    
    $c->render(json => {
        status => 'ok', 
        count => scalar(@$log_entries),
        buffered => scalar(@{$log_buffers{$full_path}})
    });
};

# Health check endpoint
get '/health' => sub ($c) {
    $c->render(json => {
        status => 'ok',
        log_dir => $log_base_dir,
        buffered_files => scalar(keys %log_buffers),
        total_buffered => sum_buffered_entries()
    });
};

# Helper: Get log file path following date+time partitioning scheme
sub get_log_filepath {
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time);
    $year += 1900;
    $mon += 1;
    
    # Directory: Idvoyages-YYYYMMDD
    my $dir_name = sprintf("Idvoyages-%04d%02d%02d", $year, $mon, $mday);
    my $dir_path = File::Spec->catdir($log_base_dir, '.jamsend', 'Tyrant', 'Idvoyages', $dir_name);
    
    # Filename: HHMM.jsons
    my $filename = sprintf("%02d%02d.jsons", $hour, $min);
    
    return ($dir_path, $filename);
}

# Helper: Flush all buffered logs to disk
sub flush_all_buffers {
    foreach my $full_path (keys %log_buffers) {
        my $entries = $log_buffers{$full_path};
        next unless @$entries;
        
        # Ensure directory exists
        my ($volume, $directories, $file) = File::Spec->splitpath($full_path);
        my $dir_path = File::Spec->catpath($volume, $directories, '');
        make_path($dir_path) unless -d $dir_path;
        
        # Append to file
        if (open my $fh, '>>', $full_path) {
            foreach my $entry (@$entries) {
                print $fh encode_json($entry), "\n";
            }
            close $fh;
            
            # Clear buffer
            delete $log_buffers{$full_path};
        } else {
            warn "Failed to open $full_path: $!";
        }
    }
    
    $last_flush = time();
}

# Helper: Sum all buffered entries
sub sum_buffered_entries {
    my $total = 0;
    $total += scalar(@{$log_buffers{$_}}) for keys %log_buffers;
    return $total;
}

# Graceful shutdown - flush on exit
app->hook(before_server_start => sub {
    app->log->info("Tyrant Logger starting on port " . ($ENV{PORT} || 3000));
});

# Flush buffers before shutdown
END {
    flush_all_buffers();
}

# Start the app
app->start;