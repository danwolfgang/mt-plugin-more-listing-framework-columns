package MoreListingFrameworkColumns::CMS;

use strict;
use warnings;

sub list_properties {
    my $app = MT->instance;

    my $menu = {
        # Activity Log
        log => {
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
        },
        # Comment
        comment => {
            id => {
                label   => 'ID',
                display => 'optional',
                order   => 1,
                base    => '__virtual.id',
                auto    => 1,
            },
            # MT has the definition to show the IP address already, but for
            # whatever reason it's only to be displayed if the
            # `ShowIPInformation` config directive is enabled. So, just
            # override that.
            ip => {
                # condition => sub { MT->config->ShowIPInformation },
                condition => 1,
            },
            url => {
                label   => 'Commenter URL',
                order   => 301,
                display => 'optional',
                auto    => 1,
                html    => \&url_link,
            },
            email => {
                label   => 'Commenter Email',
                order   => 302,
                display => 'optional',
                auto    => 1,
            },
        },
        # Authors
        author => {
            # Doesn't work?
            # id => {
            #     label   => 'ID',
            #     display => 'force',
            #     order   => 101,
            #     base    => '__virtual.id',
            #     auto    => 1,
            # },
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
                # Pages don't have an `author_id` filter type?
                # filter_type  => 'author_id',
            },
            # Doesn't work; can't find the column?
            # lockout => {
            #     display => 'optional',
            # },
        },
        # Commenters, really just a subset of Authors
        commenter => {
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
        },
        # Assets
        asset => {
            class => {
                display => 'optional',
                order   => 201,
            },
            description => {
                display => 'optional',
                order   => 300,
            },
            url => {
                label   => 'URL',
                display => 'optional',
                order   => 400,
                auto    => 1,
                html    => \&url_link,
            },
            file_path => {
                label   => 'File Path',
                display => 'optional',
                order   => 401,
                auto    => 1,
            },
            file_name => {
                display => 'optional',
                order   => 402,
            },
            file_ext => {
                display => 'optional',
                order   => 403,
            },
            image_width => {
                display => 'optional',
                order   => 501,
            },
            image_height => {
                display => 'optional',
                order   => 502,
            },
        },
        # Blog
        blog => {
            description => {
                label   => 'Description',
                display => 'optional',
                order   => 200,
                auto    => 1,
            },
            site_path => {
                label   => 'Site Path',
                display => 'optional',
                order   => 275,
                auto    => 1,
            },
            site_url => {
                label   => 'Site URL',
                display => 'optional',
                order   => 276,
                auto    => 1,
                html    => \&url_link,
            },
            archive_path => {
                label   => 'Archive Path',
                display => 'optional',
                order   => 277,
                auto    => 1,
            },
            archive_url => {
                label   => 'Archive URL',
                display => 'optional',
                order   => 278,
                auto    => 1,
                html    => \&url_link,
            },
        },
        # Website
        website => {
            description => {
                label   => 'Description',
                display => 'optional',
                order   => 200,
                auto    => 1,
            },
            site_path => {
                label   => 'Site Path',
                display => 'optional',
                order   => 275,
                auto    => 1,
            },
            site_url => {
                label   => 'Site URL',
                display => 'optional',
                order   => 276,
                auto    => 1,
                html    => \&url_link,
            },
            archive_path => {
                label   => 'Archive Path',
                display => 'optional',
                order   => 277,
                auto    => 1,
            },
            archive_url => {
                label   => 'Archive URL',
                display => 'optional',
                order   => 278,
                auto    => 1,
                html    => \&url_link,
            },
        },
    };

    my $iter = MT->model('field')->load_iter();
    while ( my $field = $iter->() ) {
        # Check that the field is an available custom field type. If not, there
        # is no reason to add the field.
        next if !$app->registry( 'customfield_types', $field->type );

        $menu->{ $field->obj_type }->{ $field->basename } = {
            label   => $field->name,
            display => 'optional',
            order   => 2000,
            html    => sub {
                my ( $prop, $obj, $app ) = @_;
                my $cf_basename = 'field.' . $field->basename;

                # Load the data dnd return the field value. If there is no
                # value, just return an empty string -- otherwise, "null" is
                # returned.
                return $obj->$cf_basename
                    || '';
            }
        };
    }

    return $menu;
}

# Build a clickable link to the URL supplied in whatever column this function
# is called from.
sub url_link {
    my ( $prop, $obj, $app ) = @_;
    my $url = $prop->col;
    return '<a href="' . $obj->$url . '">' . $obj->$url . '</a>';
}

1;

__END__
