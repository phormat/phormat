use Dancer2;
use app;
use Plack::Builder;
 
builder {
    enable 'Session', store => 'File';
    enable 'Debug', panels => [ qw<Memory Timer Environment Dancer::Version> ];
    dance;
};
