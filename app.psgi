use app;
use Dancer2;
use FindBin;
use Plack::Builder;

set appdir => "$FindBin::Bin/app";

builder {
    enable 'Session', store => 'File';
    enable 'Debug', panels => [ qw<Memory Timer Environment Dancer::Version> ];
    dance;
};
