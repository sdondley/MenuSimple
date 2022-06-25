use v6.d;

unit module Simple;

sub dist is export {
    return $?DISTRIBUTION;
}

class Menu { ... }

class Option {
    has Int $.option-number;
    has Int $.parent-menuID is rw;
    has Int $.child-menuID is rw;
    has Str $.display-string is required;
    has Any $.option-value;
    has Menu $.submenu is rw;
    has &.action is rw;
}

role Option-group {
    my %counters;
    has %.options;
    has Bool $.strip-leading-number;

    method add-options(*@options where { $_.all ~~ Str }) {
        for @options.all -> $display-string {
            self.add-option(:$display-string);
        }
        return self;
    }

    multi method add-option(Str $display-string, $option-value? where * !~~ Menu|Callable) {
        self.add-option(:$display-string, :$option-value)
    }

    multi method add-option(Str $display-string, &action, $option-value?) {
        self.add-option(:$display-string, :&action, :$option-value)
    }

    multi method add-option(Str $display-string, Menu $submenu, $option-value?) {
        self.add-option(:$display-string, :$submenu, :$option-value)
    }

    multi method add-option(Str $display-string, Menu $submenu, &action, $option-value?) {
        self.add-option(:$display-string, :$submenu, :&action, :$option-value)
    }

    multi method add-option(Str:D :$display-string is copy, Menu :$submenu, :&action, :$option-value) {
        my $counter = ++%counters{self.menuID};
        my $parent-menuID = self.menuID;
        my $child-menuID = 0;

        if $submenu {
            $child-menuID = $submenu.menuID if $submenu;
        }

        self.options{$counter} = Option.new(
                :&action,
                :$submenu,
                :$display-string,
                :$parent-menuID,
                :$child-menuID,
                :$option-value,
                option-number => $counter);
        return self;
    }

    multi method add-option(Option:D $option) {
        self.add-option(
                display-string => $option.display-string,
                submenu => $option.submenu,
                action => $option.action;
                );
    }

    multi method add-submenu(Menu:D $menu) {
        my $option-number = %counters{self.menuID};
        self.add-submenu($menu, $option-number);
    }

    multi method add-submenu(Menu:D $menu, Int:D $option-number) {
        %.options{$option-number}.submenu = $menu;
        $menu.is-submenu = True;
        %counters{$menu.menuID} = -1; #start the counter at -1
        $menu.add-option(display-string => 'Parent menu', action => { self.execute });
        %.options{$option-number}.child-menuID = $menu.menuID;
    }

    multi method add-action(&action) {
        %.options{%counters{self.menuID}}.action = &action;
    }

    multi method add-action(&action, Int:D $option-number) {
        %.options{$option-number}.action = &action;
    }

    method display-group() {
        my $format = self.option-format ~ $.option-separator;
        for self.options.sort {
            my $display = self.strip-leading-number
                    ?? .value.display-string.subst(/^^\d+ \s+? \- \s+?/, '')
                    !! .value.display-string;
            printf $format, .key, $display;
        }
    }

    method get-option($option-number where Str:D|Int:D) {
        self.options{$option-number};
    }

    method option-count() {
        return %counters{self.menuID};
    }

    method get-counters() {
        return %counters;
    }

    method !counter-init() {
        %counters{self.menuID} = 0;
    }
}

class Menu does Option-group is export {
    my $ID = 0;
    my %menus;
    has Int $!menuID = ++$ID;
    has Str $.option-format is rw = "%d - %s";
    has Str() $.selection is rw;
    has Str() $.validated-selection is rw = Nil;
    has Str $.option-separator is rw = "\n";
    has Str $.prompt = "\nMake selection: ";
    has Str $.error-msg = "\nSorry, invalid entry. Try again. ";
    has Bool $.is-submenu is rw = False;

    method menuID {
        $!menuID;
    }

    submethod new(Bool :$strip-leading-number = False) {
        self.bless(:$strip-leading-number);
    }

    submethod TWEAK() {
        %menus{self.menuID} = self;
        self!counter-init;
    }

    method get-menu(::?CLASS:U $MENU: Int:D $id)  {
        %menus{$id};
    }

    #method get-counter(::?CLASS:U $)

    multi method execute() {
        self.display;
        repeat {
            self.get-selection if !self.selection;
            self.process-selection;
        } while !self.validated-selection;
        my $option = self.get-option(self.validated-selection);
        $option.action()($option.option-value) if $option.action;
        return $option.submenu ?? $option.submenu.execute !! $option;
    }

    method display() {
        self.display-group;
        self.display-prompt;
    }

    method display-prompt() {
        print self.prompt;
    }

    method get-selection() {
        self.selection = get();
    }

    method validate-selection(--> Bool) {
        self.validated-selection = Nil;
        my $valid = False;
        try { $valid = self.selection >= self.options.keys.sort.first && !(self.selection > self.option-count) };
        return $valid;
    }

    method process-selection() {
        if !self.validate-selection {
            self.error-msg.say;
            self.display-prompt;
        }
        self.validated-selection = self.selection;
        self.selection = Nil;
    }
}


=begin pod

=head1 NAME

Menu::Simple - Create, display, and execute a simple option menu on the command line

=head1 SYNOPSIS

Simple usage:
=begin code
use Menu::Simple;

# menu sorted alphabetically
my $m = Menu.new();         # construct a menu
$m.add-option: 'Opt A';     # add options to it
$m.add-option: 'Opt B';
my $option = $m.execute;    # execute the menu
say $option.option-number;  # get user's choice

# a menu sorted with option sort numbers
my $m = Menu.new(:strip-sort-num);  # hides sort numbers
$m.add-option: '01 - Opt Z';        # displayed first
$m.add-option: '02 - Opt A';        # displayed second

# Menu options are output as:
1 - Opt Z     # not "1 - 01 - Opt Z"
2 = Opt       # not "2 - 02 - Opt A"

=end code

More advanced usage:
=begin code
use Menu::Simple;

# The code to run after an option is selected
sub some-action {
  say "running some-action";
}

# Construct a submenu and add two options to it
my $submenu = Menu.new().add-options: <'First option', 'Second option'>;

# Create a main menu
my $menu = Menu.new();

# Add an option to the main menu with an action that runs an action
$menu.add-option(
    action => &some-action,
    option-value => 'some value',
    display-string => "Do an action"
);

# Add an option that will show the submenu
$menu.add-option(
    submenu        => $submenu,
    option-value => 'some other value',
    display-string => 'Show submenu'
);

# Add an option that calls the action and shows the submenu
$menu.add-option(
    action         => &some-action,
    submenu        => $submenu,
    display-string => 'Do an action and show submenu' );

# Execute the menu
$menu.execute;

=end code

Generate a menu from a hash:
=begin code

use Menu::HashtoMenu;

my %hash = 'Option A' => 'Value A',
    'Option B' => 'Value B',
    'Option C' =>
        {submenu1 =>
            { subsubmenu => 1},
            submenu2 => 'hello' };

my $menu = HashToMenu.new(%hash2);
$menu.execute

=end code

Subroutines for adding actions and processing values of selected options
can also be added to the menu with C<HashToMenu>. See the L<Menu::HashToMenu>
class for more details.

=head1 INSTALLATION

Assuming Raku and zef is already installed, install the module with:

C<zef install Menu::Simple>

=head1 DESCRIPTION

The C<Menu::Simple> module outputs  a list of numbered menu options to a terminal.
Users are prompted to enter the option on the command line.

After a user selects an option, a submenu can be shown or an action
can be executed, or both a submenu and an action can be executed. If neither
a submenu or action is executed, an option's object is returned back can control
is given back to to code calling the menu.

Menus are always sorted alphabetically. Add a sort number to the beginning of an
option's display string to sort in a more arbitrary fashion. The sort numbers
can be hidden from the menu by using the C<:strip-sort-num> argument when
constructing the menu.

B<TIP:> When using sort numbers, leave large gaps between the numbers so you can
easily add new menus between existing menu items. Pad the option sort numbers
with leading zeroes if you expect to have more than a handful of options.

=head2 Current Features

=item Unlimited number of options can go on a menu
=item Options can execute a submenu which can be nested to an unlimited depth
=item Options can also execute an action which can run arbitrary code
=item Can traverse back to parent menu from submenu
=item Menus are displayed on the command line
=item User selections are validated
=item Customizable prompt and option delimiter
=item Menus are sorted alphabetically
=item Menus can be shown in a different order by adding leading numbers to options
=item The leading numbers from options can be optionally stripped

=head1 CLASSES AND METHODS

=head2 Menu Class

=head3 Higher level instance methods

The following higher level methods are the most useful methods for generating and
executing menus.

=head4 new()

=begin code

my $menu = Menu.new();

=end code

Creates a new menu object. Returns the menu object created.

=head4 add-options(*@options where { $options.all ~~ Str })

=begin code

my $menu = Menu.new().add-options: <'Option 1', 'Option 2', 'Option 3'>;

=end code

Accepts a series of strings to add to a menu group.

Returns the menu the option was added to.

I<Use this method to quickly add several menu options to a menu at once.>

=head4 multi method add-option(Str $display-string, $option-value? where * !~~ Menu|Callable)

=head4 multi method add-option(Str $display-string, &action, $option-value?)

=head4 multi method add-option(Str $display-string, Menu $submenu, $option-value?)

=head4 multi method add-option(Str $display-string, Menu $submenu, &action, $option-value?)

=head4 multi method add-option(Str:D :$display-string, Menu :$submenu, :&action, :$option-value)

=begin code

my $menu = Menu.new();
my $submenu = Menu.new.add-option('Option 1');
$menu.add-option('Run submenu and action', $submenu, { say 'hi' } );

=end code

Adds a single option to the menu. It can accept a submenu to display and/or a subroutine
to execute after the option is selected by the user. Options are displayed in the
menu alphabetically by default. A value can optionally be associated with
a option.

Returns the menu the option was added to.

I<Use this method to add an option to a menu that executes a submenu and/or calls a subroutine
when selected.>

=begin code

=head4 execute()

=begin code

my $menu = Menu.new().add-options: <'Option 1', 'Option 2', 'Option 3'>;
$menu.execute;

=end code

Outputs a menu, prompts the user for a selection, validates the selection, and
then returns the selected option or executes the appropriate action and/or displays
a submenu based on the user's selection.

This method wraps many of the lower-level methods for processing the user's input.

I<This method is the usual for displaying a menu and collecting, validating, and
executing responses to a user's selection after a menu is built.>

=head4 add-submenu(Menu:D $menu)

=begin code

my $main-menu = Menu.new().add-options: <'Option A', 'Option B'>;
$main-menu.add-option: Option.new(display-string => 'Some string');
my $submenu = Menu.new().add-options: <'Option A', 'Option B', 'Option C'>
$main-menu.add-submenu($submenu);

=end code

Adds a submenu to the most recently added option. The submenu will be executed if
the option is selected by the user.

I<Use this method to add a submenu to the last option in an existing menu.>

=head4 add-submenu(Menu:D $menu, Int:D $option-number)

=begin code

my $main-menu = Menu.new.add-options: <'Option A', 'Option B'>;
my $submmenu = Menu.new.add-options: <'Option 1', 'Option 2', 'Option 3'>;
$main-menu.add-submenu($submenu, 1);   # adds a submenu to o 'Option A'

=end code

Adds a submenu to an existing option as indicated by the C<$option-number> within the number group.
The submenu will be executed when the option is selected by the user.

I<Use this method to add a submenu that's executed when an option is selected.>

=head4 add-action(&action)

=begin code

sub some-action() { say 'doing some actionn' };
my $menu = Menu.new();
$menu.add-option(display-string = 'Option 1';
$menu.add-action(&some-action);  # added to Option 1

=end code

Adds an action to the last option added to the menu.
The action will get executed if the option is selected.

I<Use this method to add an action that's executed when an option is selected.>

=head4 add-action(&action, Int:D $option-number)

=begin code

my $menu = Menu.new().add-options: <'Option 1', 'Option 2', 'Option 3'>;
$menu.add-action({ say 'running action'}, 1);   # adds the action to o 'Option 1'

=end code

Adds an action to an existing option as indicated by the C<$option-number> argument.
The action is executed when the option is selected by the user.

I<Use this method to execute an action when the option is selected.>

=head3 Lower level instance methods

The Menu class methods below are typically not called directly and are provided
in case you wish to override them or have more control over how menus are executed.

=head4 display()

=begin code

my $menu = Menu.new().add-options: <'Option 1', 'Option 2', 'Option 3'>;
$menu.display;

=end code

Outputs a menu's option group and the prompt to the command line.

I<This is a lower level method and is not usually not run directly.>

=head4 display-group()

=begin code

my $menu = Menu.new().add-options: <'Option 1', 'Option 2', 'Option 3'>;
$menu.display-group;

=end code

Outputs a menu's option group to the command line.

I<This is a lower level method and is not usually not run directly.>

=head4 get-option($option-number where Str:D|Int:D)

=begin code

my $menu = Menu.new().add-options: <'Option 1', 'Option 2', 'Option 3'>;
my $option = $menu.get-option(3);

=end code

Returns an option object that has already been added to a menu. Accepts an integer value representing
the number value of ordinal position of the option in the menu.

I<This is a lower level method and is not usually not run directly.>

=head4 option-count()

=begin code

my $menu = Menu.new().add-options: <'Option 1', 'Option 2', 'Option 3'>;
my $count = $menu.option-count();

=end code

Returns the number of options that have been added to a menu.

I<This is a lower level method and is not usually not run directly.>

=head4 display-prompt()

=begin code

my $menu = Menu.new().add-options: <'Option 1', 'Option 2', 'Option 3'>;
$menu.prompt;

=end code

Displays a menu's prompt on the command line.

I<This is a lower level method and is not usually not run directly.>

=head4 get-selection()

=begin code

my $menu = Menu.new().add-options: <'Option 1', 'Option 2', 'Option 3'>;
$menu.get-selection;

=end code

Gets selection input from the user.

I<This is a lower level method and is not usually not run directly.>

=head4 validate-selection( --> Bool )

=begin code

my $menu = Menu.new().add-options: <'Option 1', 'Option 2', 'Option 3'>;
$menu.selection = 3;
my $is-valid = $menu.validate-selection;

=end code

Determines if the user has selected a valid option. Returns a True or False value.

I<This is a lower level method and is not usually not run directly.>

=head4 process-selection()

=begin code

my $menu = Menu.new().add-options: <'Option 1', 'Option 2', 'Option 3'>;
$menu.selection = 2;
$menu.process-selection;

=end code

=head4 menuID()

=begin code

my $menu1 = Menu.new().add-options: <'Option 1', 'Option 2', 'Option 3'>;
my $menu2 = Menu.new().add-options: <'Option A', 'Option B', 'Option C'>;
$menu1.menuID;   # returns the Int value '1'
$menu2.menuID;   # returns the Int value '2'

=end code

Returns the internal menu id of the menu.

I<This is a lower level method and is not usually not run directly.>

=head3 Class methods

=head4 get-menu(Int:D $id)

=begin code

my $menu = Menu.new().add-options: <'Option 1', 'Option 2', 'Option 3'>;
my $submenu = Menu.new().add-options: <'Option A', 'Option B', 'Option C'>;
Menu.get-menu(1);   # returns $menu
Menu.get-menu(2);   # returns $submenu

=end code

Returns the menu that corresponds to the C<$id> passed to C<get-menu>

I<This is a lower level method and is not usually not run directly.>

=head4 get-counters()

Dumps the hash containing the options counters for all menus

I<This is a lower level method and is not usually not run directly.>


=head3 Attributes

=head4 has Bool $.strip-sort-num;

Hides the sort number which can be used for sorting options.
The menu will Look for digits at the beginning of the option's display
string followed by a dash character. Whitespace surrounding
the dash is optional.

=head4 %.options

A hash of the options in an options groups.

=head4 $.menuID = ++$ID;

A unique ID number for the menu

=head4 $.option-format is rw = "%d - %s";

The format string for displaying options where C<%d> is the option number
and C<%s> is the display string.

=head4 $.selection is rw;

The string the user has input

=head4 $.validated-selection is rw = Nil;

The validated string of the user's input

=head4 $.option-separator is rw = "\n";

The string that separates menu options

=head4 $.prompt = "\nMake selection: ";

The prompt shown to the user

=head4 $.error-msg = "\nSorry, invalid entry. Try again. ";

The error show when a user make an invalid selection

=head2 Option Class

=head3 Methods

=head4 Option.new(Str:D :display-string, :action, :submenu)

=begin code

my $menu = Option.new(
    display-string => Str,
    action => Callable?,
    submenu => Menu?
);

=end code

Creates a new option.

The C<display-string> is the string shown to the user.

The C<action> is the subroutine run when the option is selected.

The C<submenu> is the menu displayed when the option is selected.

=head3 Attributes

=head4 $.option-number;

The number of the option

=head4 $.option-value;

An optional value associated with an option

=head4 $.display-string is required;

The string shown when an option is printed

=head4 $.submenu is rw;

The submenu executed when an option is selected

=head4 Int $.parent-menuID is rw;

The menuID of the option belongs to

=head4 Int $.child-menuID is rw;

The menuID of the submenu the option executes. Return 0 if none.

=head4 &.action is rw;

The action executed when an option is selected

=end pod