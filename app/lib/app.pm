package app;

use Dancer2;
use Dancer2::Plugin::Database;
use Template;

my @all_chains = database->quick_select('chains', {});

get '/' => sub {
  template 'display_chain', { chains => [ @all_chains ] };
};

true;
