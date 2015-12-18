package MoreListingFrameworkColumns::CMS;

use strict;
use warnings;
use MT::Util qw( encode_html );

use MoreListingFrameworkColumns::Object::Asset;
use MoreListingFrameworkColumns::Object::Author;
use MoreListingFrameworkColumns::Object::Blog;
use MoreListingFrameworkColumns::Object::Comment;
use MoreListingFrameworkColumns::Object::Entry;
use MoreListingFrameworkColumns::Object::Field;
use MoreListingFrameworkColumns::Object::Page;
use MoreListingFrameworkColumns::Object::Log;

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
        __virtual => {
            modified_by => {
                base    => '__virtual.author_name',
                label   => 'Modified By',
                display => 'Optional',
                order   => 701,
                raw     => sub {
                    my ( $prop, $obj ) = @_;
                    my $col    = 'modified_by';
                    if ( $obj->$col ) {
                        my $author = MT->model('author')->load( $obj->$col );
                        return $author
                            ? ( $author->nickname || $author->name )
                            : MT->translate('*User deleted*');
                    }
                },
                terms => sub {
                    my $prop = shift;
                    my ( $args, $load_terms, $load_args ) = @_;
                    my $col     = 'modified_by';
                    my $driver  = $prop->datasource->driver;
                    my $colname = $driver->dbd->db_column_name(
                        $prop->datasource->datasource, $col );
                    $prop->{col} = 'name';
                    my $name_query = $prop->super(@_);
                    $prop->{col} = 'nickname';
                    my $nick_query = $prop->super(@_);
                    $load_args->{joins} ||= [];
                    push @{ $load_args->{joins} },
                        MT->model('author')->join_on(
                        undef,
                        [   [   {   id => \"= $colname",
                                    %$name_query,
                                },
                                (   $args->{'option'} eq 'not_contains'
                                    ? '-and'
                                    : '-or'
                                ),
                                {   id => \"= $colname",
                                    %$nick_query,
                                },
                            ]
                        ],
                        {}
                    );
                },
                bulk_sort => sub {
                    my $prop = shift;
                    my ($objs) = @_;
                    my $col       = 'modified_by';
                    my %author_id = map { $_->$col => 1 } @$objs;
                    my @authors   = MT->model('author')
                        ->load( { id => [ keys %author_id ] } );
                    my %nickname
                        = map { $_->id => $_->nickname } @authors;
                    return sort {
                        $nickname{ $a->$col } cmp $nickname{ $b->$col }
                    } @$objs;
                },
            },
        },

        asset     => MoreListingFrameworkColumns::Object::Asset::list_properties,
        author    => MoreListingFrameworkColumns::Object::Author::list_properties,
        blog      => MoreListingFrameworkColumns::Object::Blog::list_properties,
        comment   => MoreListingFrameworkColumns::Object::Comment::list_properties,
        commenter => MoreListingFrameworkColumns::Object::Author::commenter_list_properties,
        entry     => MoreListingFrameworkColumns::Object::Entry::list_properties,
        log       => MoreListingFrameworkColumns::Object::Log::list_properties,
        page      => MoreListingFrameworkColumns::Object::Page::list_properties,
        website   => MoreListingFrameworkColumns::Object::Blog::list_properties,

        # Custom Fields
        field     => MoreListingFrameworkColumns::Object::Field::list_properties,
    };

    # Add Custom Field columns to the listing framework screens.
    MoreListingFrameworkColumns::Object::Field::add_custom_field_columns($menu);

    return $menu;
}

# Build a clickable link to the URL supplied in whatever column this function
# is called from.
sub url_link {
    my ( $prop, $obj, $app ) = @_;
    my $url = $prop->col;
    return '<a href="' . $obj->$url . '" target="_blank">' . $obj->$url . '</a>';
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
