package MoreListingFrameworkColumns::Object::Blog;

use strict;
use warnings;

# At least for now, Blog and Website listing screens are being augmented with
# the same information.
sub list_properties {
    return {
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
            html    => sub { MoreListingFrameworkColumns::CMS::url_link(@_) },
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
            html    => sub { MoreListingFrameworkColumns::CMS::url_link(@_) },
        },
        theme_label => {
            label   => 'Theme',
            display => 'optional',
            order   => 605,
            html    => sub { theme_label(@_) },
        },
    };
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

1;

__END__
