# More Listing Framework Columns plugin for Movable Type

Movable Type's Listing Framework is a fantastic way to get an overview and
review content -- it's responsible for the "Manage" screens. The column sorting
and filtering options are very powerful!

You may have noticed, however, that not all content is visible on the Listing
Framework screens. This plugin adds more columns to the Listing Framework,
including Custom Fields!

By default, user-created Listing Framework filters are available to only the
user that created them. Any user can access them through System Overview >
Listing Filters, however this is less convenient than simply having them
available on the screen they are for. So, this plugin will also make any
user-created filter available to all users, making it easy to share filters
with all users.

## Included Columns

The following is a list of additional columns this plugin adds to the Listing
Framework (in addition to Custom Fields for any object type):

* Activity Log: ID, Class, Category, Level, Metadata

* Assets: Class, Description, URL, File Path, File Name, File Extension, Image
  Width, Image Height

* Author: ID, Basename, Preferred Language, Page Count, Lockout Status

* Blog: Description, Site Path, Site URL, Archive Path, Archive URL, Theme

* Comment: ID, IP Address, Commenter URL, Commenter Email

  Also, updated the Entry/Page column to include both a link to the edit the
  Entry/Page, as well as a link to view the published page.

* Commenters: Basename, Preferred Language

* Custom Fields: ID, Required, Description, Field Options, Basename, and
  Default Value. Also, simplified the Template Tag display.

* Website: Description, Site Path, Site URL, Archive Path, Archive URL, Theme

# Prerequisites

* Movable Type 5.1+

# Installation

To install this plugin follow the instructions found here:

http://tinyurl.com/easy-plugin-install

# Use

Visit any Listing Framework page and click the Display Options button in the
upper-right corner of the screen to enable any additional columns or fields
available.

Custom Fields will be available for display, though note that the displayed
value may not be what you expect. Some Custom Fields types such as "Single-Line
Text" will display the content of the field, while other Custom Field types
such as "Checkbox" will simply display `1` or `0` to indicate true or
false/checked or unchecked. Other more complex Custom Fields, such as those
found in the
[More Custom Fields plugin](http://eatdrinksleepmovabletype.com/plugins/more_custom_fields/)
have complex data structures that may not display clearly.

Dan would like to improve the display of those fields. If you'd like to help
fund that work, [send an email](mailto:contact@uinnovations.com).

# License

This plugin is licensed under the same terms as Perl itself.

#Copyright

Copyright 2014, uiNNOVATIONS LLC. All rights reserved.
