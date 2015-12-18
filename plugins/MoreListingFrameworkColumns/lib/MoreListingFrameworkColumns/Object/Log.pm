package MoreListingFrameworkColumns::Object::Log;

use strict;
use warnings;

sub list_properties {
    return {
        id => {
            label   => 'ID',
            display => 'optional',
            order   => 1,
            base    => '__virtual.id',
            auto    => 1,
        },
        class => {
            label   => 'Class',
            order   => 1001,
            display => 'optional',
            auto    => 1,
        },
        category => {
            label   => 'Category',
            order   => 1002,
            display => 'optional',
            auto    => 1,
        },
        level => {
            label   => 'Level',
            order   => 1003,
            display => 'optional',
            auto    => 1,
        },
        metadata => {
            label   => 'Metadata',
            order   => 1004,
            display => 'optional',
            auto    => 1,
        },
        # MT has a definition for the "By" column but it's forced on by
        # default, which is not necessarily useful.
        by => {
            display => 'default',
        },
    };
}

1;

__END__
