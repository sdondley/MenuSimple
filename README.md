[![Actions Status](https://github.com/sdondley/MenuSimple/workflows/test/badge.svg)](https://github.com/sdondley/MenuSimple/actions)

NAME
====

Menu::Simple - Create, display, and execute a simple option menu on the command line

SYNOPSIS
========

Simple usage:

    my $m = Menu.new();         # construct a menu
    $m.add-option: 'Opt A';     # add options to it
    $m.add-option: 'Opt B';
    my $option = $m.execute;    # execute the menu
    say $option.option-number;  # get user's choice

More advanced usage:

    # The code to run after an option is selected
    sub some-action {
      say "running some-action";
    }

    # Construct a submenu and add two options to it
    my $submenu = Menu.new().add-options: <First option, Second option>;

    # Create a main menu
    my $menu = Menu.new();

    # Add an option to the main menu with an action that runs an action
    $menu.add-option(
        action => &some-action,
        display-string => "Do an action"
    );

    # Add an option that will show the submenu
    $menu.add-option(
        submenu        => $submenu,
        display-string => "Show submenu"
    );

    # Add an option that calls the action and shows the submenu
    $menu.add-option(
        action         => &some-action,
        submenu        => $submenu,
        display-string => "Do an action and show submenu" );

    # Execute the menu
    $menu.execute;

INSTALLATION
============

Assuming Raku and zef is already installed, install the module with:

`zef install Menu::Simple`

DESCRIPTION
===========

The `Menu::Simple` module outputs a list of numbered menu options to a terminal. Users are prompted to enter the option on the command line.

After a user selects an option, a submenu can be shown or an action can be executed, or both a submenu and an action can be executed. If neither a submenu or action is executed, an option's object is returned back can control is given back to to code calling the menu.

CLASSES AND METHODS
===================

Menu Class
----------

### Higher level instance methods

The following higher level methods are the most useful methods for generating and executing menus.

#### new()

    my $menu = Menu.new();

Creates a new menu object. Returns the menu object created.

#### add-options(*@options where { $options.all ~~ Str })

    my $menu = Menu.new().add-options: <Option 1, Option 2, Option 3>;

Accepts a series of strings to add to a menu group.The items will be shown in the same order as they are added to the list.

Returns the menu the option was added to.

*Use this method to quickly add several menu options to a menu at once.*

#### multi add-option(Str:D :$display-string, Menu :$submenu, :&action)

#### multi add-option($display-string, Menu $submenu?, &action?)

#### multi add-option($display-string, Menu $submenu)

#### multi add-option($display-string, &action)

#### multi add-option(Option:D $option)

    my $menu = Menu.new();
    my $submenu = Menu.new.add-option('Option 1');
    $menu.add-option('Run submenu and action', $submenu, { say 'hi' } );

Adds a single option to the menu. It can accept a submenu to display and/or a subroutine to execute after the option is selected by the user. Options are displayed in the menu in the order they were added to the menu.

Returns the menu the option was added to.

*Use this method to add an option to a menu that executes a submenu and/or calls a subroutine when selected.*

    =head4 execute()

    =begin code

    my $menu = Menu.new().add-options: <Option 1, Option 2, Option 3>;
    $menu.execute;

Outputs a menu, prompts the user for a selection, validates the selection, and then returns the selected option or executes the appropriate action and/or displays a submenu based on the user's selection.

This method wraps many of the lower-level methods for processing the user's input.

*This method is the usual for displaying a menu and collecting, validating, and executing responses to a user's selection after a menu is built.*

#### add-submenu(Menu:D $menu)

    my $main-menu = Menu.new().add-options: <Option A, Option B>;
    $main-menu.add-option: Option.new(display-string => 'Some string');
    my $submenu = Menu.new().add-options: <Option A, Option B, Option C>
    $main-menu.add-submenu($submenu);

Adds a submenu to the most recently added option. The submenu will be executed if the option is selected by the user.

*Use this method to add a submenu to the last option in an existing menu.*

#### add-submenu(Menu:D $menu, Int:D $option-number)

    my $main-menu = Menu.new.add-options: <Option A, Option B>;
    my $submmenu = Menu.new.add-options: <Option 1, Option 2, Option 3>;
    $main-menu.add-submenu($submenu, 1);   # adds a submenu to o 'Option A'

Adds a submenu to an existing option as indicated by the `$option-number` within the number group. The submenu will be executed when the option is selected by the user.

*Use this method to add a submenu that's executed when an option is selected.*

#### add-action(&action)

    sub some-action() { say 'doing some actionn' };
    my $menu = Menu.new();
    $menu.add-option(display-string = 'Option 1';
    $menu.add-action(&some-action);  # added to Option 1

Adds an action to the last option added to the menu. The action will get executed if the option is selected.

*Use this method to add an action that's executed when an option is selected.*

#### add-action(&action, Int:D $option-number)

    my $menu = Menu.new().add-options: <Option 1, Option 2, Option 3>;
    $menu.add-action({ say 'running action'}, 1);   # adds the action to o 'Option 1'

Adds an action to an existing option as indicated by the `$option-number` argument. The action is executed when the option is selected by the user.

*Use this method to execute an action when the option is selected.*

### Lower level instance methods

The Menu class methods below are typically not called directly and are provided in case you wish to override them or have more control over how menus are executed.

#### display()

    my $menu = Menu.new().add-options: <Option 1, Option 2, Option 3>;
    $menu.display;

Outputs a menu's option group and the prompt to the command line.

*This is a lower level method and is not usually not run directly.*

#### display-group()

    my $menu = Menu.new().add-options: <Option 1, Option 2, Option 3>;
    $menu.display-group;

Outputs a menu's option group to the command line.

*This is a lower level method and is not usually not run directly.*

#### get-option($option-number where Str:D|Int:D)

    my $menu = Menu.new().add-options: <Option 1, Option 2, Option 3>;
    my $option = $menu.get-option(3);

Returns an option object that has already been added to a menu. Accepts an integer value representing the number value of ordinal position of the option in the menu.

*This is a lower level method and is not usually not run directly.*

#### option-count()

    my $menu = Menu.new().add-options: <Option 1, Option 2, Option 3>;
    my $count = $menu.option-count();

Returns the number of options that have been added to a menu.

*This is a lower level method and is not usually not run directly.*

#### display-prompt()

    my $menu = Menu.new().add-options: <Option 1, Option 2, Option 3>;
    $menu.prompt;

Displays a menu's prompt on the command line.

*This is a lower level method and is not usually not run directly.*

#### get-selection()

    my $menu = Menu.new().add-options: <Option 1, Option 2, Option 3>;
    $menu.get-selection;

Gets selection input from the user.

*This is a lower level method and is not usually not run directly.*

#### validate-selection( --> Bool )

    my $menu = Menu.new().add-options: <Option 1, Option 2, Option 3>;
    $menu.selection = 3;
    my $is-valid = $menu.validate-selection;

Determines if the user has selected a valid option. Returns a True or False value.

*This is a lower level method and is not usually not run directly.*

#### process-selection()

    my $menu = Menu.new().add-options: <Option 1, Option 2, Option 3>;
    $menu.selection = 2;
    $menu.process-selection;

#### menuID()

    my $menu1 = Menu.new().add-options: <Option 1, Option 2, Option 3>;
    my $menu2 = Menu.new().add-options: <Option A, Option B, Option C>;
    $menu1.menuID;   # returns the Int value '1'
    $menu2.menuID;   # returns the Int value '2'

Returns the internal menu id of the menu.

*This is a lower level method and is not usually not run directly.*

### Class methods

#### get-menu(Int:D $id)

    my $menu = Menu.new().add-options: <Option 1, Option 2, Option 3>;
    my $submenu = Menu.new().add-options: <Option A, Option B, Option C>;
    Menu.get-menu(1);   # returns $menu
    Menu.get-menu(2);   # returns $submenu

Returns the menu that corresponds to the `$id` passed to `get-menu`

*This is a lower level method and is not usually not run directly.*

#### get-counters()

Dumps the hash containing the options counters for all menus

*This is a lower level method and is not usually not run directly.*

### Attributes

#### %.options

A hash of the options in an options groups.

#### $.menuID = ++$ID;

A unique ID number for the menu

#### $.option-format is rw = "%d - %s";

The format string for displaying options where `%d` is the option number and `%s` is the display string.

#### $.selection is rw;

The string the user has input

#### $.validated-selection is rw = Nil;

The validated string of the user's input

#### $.option-separator is rw = "\n";

The string that separates menu options

#### $.prompt = "\nMake selection: ";

The prompt shown to the user

#### $.error-msg = "\nSorry, invalid entry. Try again. ";

The error show when a user make an invalid selection

Option Class
------------

### Methods

#### Option.new(Str:D :display-string, :action, :submenu)

    my $menu = Option.new(
        display-string => Str,
        action => Callable?,
        submenu => Menu?
    );

Creates a new option.

The `display-string` is the string shown to the user.

The `action` is the subroutine run when the option is selected.

The `submenu` is the menu displayed when the option is selected.

### Attributes

#### $.option-number;

The number of the option

#### $.display-string is required;

The string shown when an option is printed

#### $.submenu is rw;

The submenu executed when an option is selected

#### Int $.parent-menuID is rw;

The menuID of the option belongs to

headr
=====

Int $.child-menuID is rw;

The menuID of the submenu the option executes. Return 0 if none.

#### &.action is rw;

The action executed when an option is selected

