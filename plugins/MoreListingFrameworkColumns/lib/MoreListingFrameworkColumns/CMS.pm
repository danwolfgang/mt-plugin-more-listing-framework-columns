package MoreListingFrameworkColumns::CMS;

use strict;
use warnings;

# Update all of the listing framework screens to include filters that any user
# has created, not just the filters the current user created.
sub list_template_param {
    my ($cb, $app, $param, $tmpl) = @_;
    my $type = $param->{object_type};

    my $filters = build_filters( $app, $type, encode_html => 1 );

    require JSON;
    my $json = JSON->new->utf8(0);

    # Update the parameters with the new filters.
    $param->{filters}     = $json->encode($filters);
    $param->{filters_raw} = $filters;

}

# Listing screen .js calls mode=filtered_list (MT::CMS::Common::filtered_list),
#   which overwrites .js filter list created in list_template_param sub above
# Update .js data structure on listing framework screens to include filters
#   that any user has created, not just the filters the current user created.
sub cms_filtered_list_param {
    my ( $cb, $app, $param, $objs ) = @_;

    my $q = $app->param;
    my $type = $q->param('datasource');

    # Update .js data structure with the new filters.
    my $filters = build_filters( $app, $type, encode_html => 1 );
    $param->{filters} = $filters;
}

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
        },
        # Pages - Define 'author_id' filter type for Pages
        page => {
            author_id => {
                base            => 'entry.author_id',
                label_via_param => sub {
                    my $prop = shift;
                    my ( $app, $val ) = @_;
                    my $author = MT->model('author')->load($val);
                    return MT->translate( 'Pages by [_1]', $author->nickname, );
                },
            },
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
            theme_label => {
                label   => 'Theme',
                display => 'optional',
                order   => 605,
                html    => \&theme_label,
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
            theme_label => {
                label   => 'Theme',
                display => 'optional',
                order   => 605,
                html    => \&theme_label,
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
            condition => sub {
                my ($prop) = shift;

                # Show the field at the System Overview
                return 1 if !$app->blog;

                # Show the field if the field is a system-wide field
                return 1 if !$field->blog_id;

                # Show the field at the blog/website level
                return 1 if
                    $app->blog
                    && $app->blog->id eq $field->blog_id;

                # Show the field at the website level if the field is in a
                # child blog.
                my $field_blog = $app->model('blog')->load( $field->blog_id );
                return 1 if
                    $app->blog
                    && $app->blog->class eq 'website'
                    && $field_blog->parent_id eq $app->blog->id;

                return 0;
            },
            html    => sub {
                my ( $prop, $obj, $app ) = @_;

                # Load the data and return the field value. If there is no
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

sub theme_label {
    my ( $prop, $obj, $app ) = @_;
    my $id = $obj->theme_id
        or return '<em>No theme applied</em>';

    # look for registry.
    my $registry = MT->registry('themes');
    require MT::Theme;
    my $theme = MT::Theme->_load_from_registry( $id, $registry->{$id} );

    ## if not exists in registry, going to look for theme directory.
    $theme = MT::Theme->_load_from_themes_directory($id)
        unless defined $theme;

    ## at last, search for template set.
    $theme = MT::Theme->_load_pseudo_theme_from_template_set($id)
        unless defined $theme;

    return defined $theme && $theme->registry('label')
        ? $theme->registry('label')
        : "Failed to load theme: $id";
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

# From MT::CMS::Filter
# Saved filters should be available for all users. Below, the filter model load
# should not be restricted to the user that created it.
sub build_filters {
    my ( $app, $type, %opts ) = @_;
    my $obj_class = MT->model($type);

    # my @user_filters = MT->model('filter')
    #     ->load( { author_id => $app->user->id, object_ds => $type } );
    my @user_filters = MT->model('filter')
        ->load( { object_ds => $type } );

    @user_filters = map { $_->to_hash } @user_filters;

    my @sys_filters;
    my $sys_filters = MT->registry( system_filters => $type );
    for my $sys_id ( keys %$sys_filters ) {
        next if $sys_id =~ /^_/;
        my $sys_filter = MT::CMS::Filter::system_filter( $app, $type, $sys_id )
            or next;
        push @sys_filters, $sys_filter;
    }
    @sys_filters = sort { $a->{order} <=> $b->{order} } @sys_filters;

    #FIXME: Is this always right path to get it?
    my @legacy_filters;
    my $legacy_filters
        = MT->registry( applications => cms => list_filters => $type );
    for my $legacy_id ( keys %$legacy_filters ) {
        next if $legacy_id =~ /^_/;
        my $legacy_filter = MT::CMS::Filter::legacy_filter( $app, $type, $legacy_id )
            or next;
        push @legacy_filters, $legacy_filter;
    }

    my @filters = ( @user_filters, @sys_filters, @legacy_filters );
    for my $filter (@filters) {
        my $label = $filter->{label};
        if ( 'CODE' eq ref $label ) {
            $filter->{label} = $label->();
        }
        if ( $opts{encode_html} ) {
            MT::Util::deep_do(
                $filter,
                sub {
                    my $ref = shift;
                    $$ref = MT::Util::encode_html($$ref);
                }
            );
        }
    }
    return \@filters;
}

1;

__END__
