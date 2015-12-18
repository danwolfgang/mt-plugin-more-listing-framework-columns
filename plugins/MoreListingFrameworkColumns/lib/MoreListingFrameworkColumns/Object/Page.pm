package MoreListingFrameworkColumns::Object::Page;

use strict;
use warnings;

sub list_properties {
    return {
        modified_by => {
            base => '__virtual.modified_by',
        },
        # Define 'author_id' filter type for Pages
        author_id => {
            base            => 'entry.author_id',
            label_via_param => sub {
                my $prop = shift;
                my ( $app, $val ) = @_;
                my $author = MT->model('author')->load($val);
                return MT->translate( 'Pages by [_1]', $author->nickname, );
            },
        },
    };
}

1;

__END__
