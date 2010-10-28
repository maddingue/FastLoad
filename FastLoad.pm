package FastLoad;

my $cachefile;
my $cache;

BEGIN {

    # load the cache
    $cachefile = '.fastload';
    my $code = do { open my $fh, $cachefile; local $/; <$fh> };
    eval $code;

    # load the hook
    unshift @INC, \&fastload unless grep { "$_" eq \&fastlog . '' } @INC;
}

sub fastload {
    my ( $code, $module ) = @_;

    # ensure our hook remains first in @INC
    @INC = ( $code, grep { $_ ne $code } @INC )
        if $INC[0] ne $code;

    # if we know where the source is, just load it
    if ( exists $cache->{$module} ) {
        open my $fh, $cache->{$module} or return;
        return $fh;
    }

    # let Perl ultimately find the required file
    return;
}

END {

    # update cache with content of %INC
    while ( my ( $module, $file ) = each %INC ) {
        next if ref $file;
        next if !-e $file;
        $cache->{$module} = $file;
    }

    # save cache
    open my $fh, '>', $cachefile;
    require Data::Dumper;
    print $fh Data::Dumper->Dump( [$cache], ['$cache'] );
}

1;

