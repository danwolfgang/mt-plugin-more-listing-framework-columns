package MoreListingFrameworkColumns::Object::Entry;

use strict;
use warnings;

sub list_properties {
    return {
        created_on => {
            base    => '__virtual.created_on',
            auto    => 1,
            display => 'optional',
            order   => 599,
        },
        modified_by => {
            base => '__virtual.modified_by',
        },
    };
}

1;

__END__
