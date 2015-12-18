package MoreListingFrameworkColumns::Object::Author;

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
            # MT::Author sets empty 'view' scope for 'id' column, which
            # disables its display at any scope (system, website, blog).
            view    => [ 'system' ],
        },
        basename => {
            label   => 'Basename',
            order   => 1001,
            display => 'optional',
            auto    => 1,
        },
        preferred_language => {
            label   => 'Preferred Language',
            order   => 1002,
            display => 'optional',
            auto    => 1,
        },
        page_count => {
            label        => 'Pages',
            filter_label => '__PAGE_COUNT',
            display      => 'optional',
            order        => 301,
            base         => '__virtual.object_count',
            col_class    => 'num',
            count_class  => 'page',
            count_col    => 'author_id',
            # Pages don't have an `author_id` filter type by default.
            # 'author_id' filter type for Pages is defined below.
            filter_type  => 'author_id',
        },
        lockout => {
            display   => 'optional',
            # Generate content to be displayed in table cells for 'lockout'
            # column because 'lockout' is not a real author field.
            raw       => sub {
                my $prop = shift;
                my ( $obj, $app, $opts ) = @_;
                return $obj->locked_out
                    ? '* ' . MT->translate('Locked Out') . ' *'
                    : MT->translate('Not Locked Out');
            },
            # Sort users on locked_out: 1 = Locked out; 0 = Not locked out
            # Reverse direction of sort so locked out users are displayed
            # first when 'Lockout' column is clicked the first time.
            bulk_sort => sub {
                my $prop = shift;
                my ($objs) = @_;
                return sort { $b->locked_out <=> $a->locked_out } @$objs;
            },
        },
    };
}

# Commenters are really just a subset of authors.
sub commenter_list_properties {
    return {
        basename => {
            label   => 'Basename',
            order   => 1001,
            display => 'optional',
            auto    => 1,
        },
        preferred_language => {
            label   => 'Preferred Language',
            order   => 1002,
            display => 'optional',
            auto    => 1,
        },
    };
}

1;

__END__
