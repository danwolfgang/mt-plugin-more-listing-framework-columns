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
            # MT has a definition for the "By" column but it's forced on by
            # default, which is not necessarily useful.
            by => {
                display => 'default',
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
            # This has been defined already and is the Entry/Page column, used
            # to show a link to the Edit Entry/Edit Page screen for the
            # associated entry/page. We want to add to this, to show a
            # published page link, too.
            entry => {
                bulk_html => sub {
                    my $prop = shift;
                    my ( $objs, $app ) = @_;
                    my %entry_ids = map { $_->entry_id => 1 } @$objs;
                    my @entries
                        = MT->model('entry')
                        ->load( { id => [ keys %entry_ids ], },
                        { no_class => 1, } );
                    my %entries = map { $_->id => $_ } @entries;
                    my @result;

                    for my $obj (@$objs) {
                        my $id    = $obj->entry_id;
                        my $entry = $entries{$id};
                        if ( !$entry ) {
                            push @result, MT->translate('Deleted');
                            next;
                        }

                        my $type = $entry->class_type;
                        my $img
                            = MT->static_path
                            . 'images/nav_icons/color/'
                            . $type . '.gif';
                        my $title_html
                            = MT::ListProperty::make_common_label_html( $entry,
                            $app, 'title', 'No title' );

                        my $permalink = $entry->permalink;
                        my $view_img
                            = MT->static_path . 'images/status_icons/view.gif';
                        my $view_link_text
                            = MT->translate( 'View [_1]', $entry->class_label );
                        my $view_link = $entry->status == MT::Entry::RELEASE()
                            ? qq{
                            <span class="view-link">
                              <a href="$permalink" target="_blank">
                                <img alt="$view_link_text" src="$view_img" />
                              </a>
                            </span>
                        }
                            : '';

                        push @result, qq{
                            <span class="icon target-type $type">
                              <img src="$img" />
                            </span>
                            $title_html
                            $view_link
                        };
                    }
                    return @result;
                },
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

    my $iter = MT->model('field')->load_iter(
        undef,
        {
            sort => 'name',
        }
    );
    my $order = 10000;
    while ( my $field = $iter->() ) {
        # Check that the field is an available custom field type. If not, there
        # is no reason to add the field.
        next if !$app->registry( 'customfield_types', $field->type );

        my $cf_basename = 'field.' . $field->basename;

        $menu->{ $field->obj_type }->{ $field->basename } = {
            label   => $field->name,
            display => 'optional',
            order   => $order++,
            html    => sub {
                my ( $prop, $obj, $app ) = @_;

                # Load the data dnd return the field value. If there is no
                # value, just return an empty string -- otherwise, "null" is
                # returned.
                return $obj->$cf_basename
                    || '';
            },
            filter_tmpl => '<mt:var name="filter_form_string">',
            grep => sub {
                my $prop = shift;
                my ( $args, $objs, $opts ) = @_;
                my $option = $args->{option};
                my $query  = $args->{string};

                # my @result = grep { $_->$cf_basename =~ /little/ } @$objs;
                my @result = grep { 
                    filter_custom_field({
                        option => $option,
                        query  => $query,
                        field  => $_->$cf_basename,
                    }) 
                } @$objs;

                return @result;
            },
            # Make the column sortable
            bulk_sort => sub {
                my $prop = shift;
                my ($objs, $opts) = @_;
                return sort {
                    $a->$cf_basename cmp $b->$cf_basename
                } @$objs;
            },
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

# Filter custom fields with the specified text and option. This isn't perfect;
# it's really focused on parsing strings. Other, more complext, types of CF data
# probably can't be well-filtered by this basic capability.
sub filter_custom_field {
    my ($arg_ref) = @_;
    my $option = $arg_ref->{option};
    my $query  = $arg_ref->{query};
    my $field  = $arg_ref->{field};

    if ( 'equal' eq $option ) {
        return $field =~ /^$query$/;
    }
    if ( 'contains' eq $option ) {
        return $field =~ /$query/i;
    }
    elsif ( 'not_contains' eq $option ) {
        return $field !~ /$query/i;
    }
    elsif ( 'beginning' eq $option ) {
        return $field =~ /^$query/i;
    }
    elsif ( 'end' eq $option ) {
        return $field =~ /$query$/i;
    }
    
}

1;

__END__

