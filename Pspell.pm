package Text::Pspell;

require DynaLoader;

use vars qw/  @ISA $VERSION /;
@ISA = 'DynaLoader';

$VERSION = '0.03';

bootstrap Text::Pspell $VERSION;

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Text::Pspell - Perl interface to the Pspell library

=head1 SYNOPSIS

    use Text::Pspell;
    my $speller = Text::Pspell->new;

    die unless $speller;


    # Set some options
    $speller->set_option('language-tag','en_US');
    $speller->set_option('sug-mode','fast');


    # check a word
    print $speller->check( $word )
          ? "$word found\n"
          : "$word not found!\n";

    # lookup up words
    my @suggestions = $speller->suggest( $misspelled );


    # lookup config options
    my $language = $speller->get_option('language-tag');
    print $speller->errstr unless defined $language;

    # dump config settings
    $speller->print_config || $speller->errstr;

    


=head1 DESCRIPTION

B<NOTE:> Aspell/Pspell has been replaced by GNU Aspell.  Unless
you are using an old installation of Aspell/Pspell you should use
Text::Aspell instead of this module.  Text::Aspell is available on
the CPAN.  Information on GNU Aspell can be found at http://aspell.net.

This module provides a Perl interface to the Pspell library.
The Pspell library provides access to system spelling libraries, and specifically
the Aspell spell checker.
This module is to meet the need of looking up many
words, one at a time, in a single session.

This is a perl xs interface which should provide good performance (for example, compared
to forking the aspell program for every word).

For example, a tiny run of about 400 word lookups resulted in:

    aspell-fast: 18.44 seconds
    pspell-fast:  0.63 seconds

Where aspell-fast was forking (about 4 words perl fork) and pspell-fast was using this
module ("fast" refers to the spelling mode used).


=head1 DEPENDENCIES

You must have installed Pspell on your system (and very likely Aspell, too).
Download from:

    Pspell: http://pspell.sourceforge.net
    Aspell: http://aspell.sourceforge.net


=head1 METHODS

The following methods are available:

=over 4

=item $speller = Text::Pspell->new;

Creates a new speller object.  New does not take any parameters (future version
may allow options set by passing in a hash reference of options and value pairs).
Returns C<undef> if the object could not be created, which is unlikely.

=item $speller->set_option($tag, $value);

Sets the configuration option C<$tag> to the value of C<$value>.
Returns C<undef> on error, and the error message can be printed with $speller->errstr.
You generally set configuration options before calling the $speller->create_manager
method.  See the Pspell and Aspell documentation for the available configuration settings
and how (and when) they may be used.

=item $speller->remove_option($tag);

Removes (sets to the default value) the configuration option specified by C<$tag>.
Returns C<undef> on error, and the error message can be printed with $speller->errstr.
You may only set configuration options before calling the $speller->create_manager
method.

=item $speller->get_option($tag);

Returns the current setting for the given tag.
Returns C<undef> on error, and the error message can be printed with $speller->errstr.
Note that this may return different results depending on if it's called before or after
$speller->create_manager is called.  


=item $speller->print_config;

Prints the current configuration to STDOUT.  Useful for debugging.
Note that this will return different results depending on if it's called before or after
$speller->create_manager is called.  

=item $speller->errstr;

Returns the error string from the last error.  Check the previous call for an C<undef> return
value before calling this method

=item $speller->errnum;

Returns the error number from the last error.  Some errors may only set the
error string ($speller->errstr) on errors, so it's best to check use the errstr method
over this method.


=item $speller->check($word);

Checks if a word is found in the dictionary.  Returns true if the word is found
in the dictionary, false but defined if the word is not in the dictionary.
Returns C<undef> on error, and the error message can be printed with $speller->errstr.

This calls $speller->create_manager if the manager has not been created by an
explicit call to $speller->create_manager.

=item @suggestions = $speller->suggest($word)

Returns an array of word suggestions for the specified word.  The words are returned
with the best guesses at the start of the list.


=item $speller->create_manager;

This method is normally not called by your program.
It is called automatically the first time $speller->check() or
$speller->suggest() is called to create a spelling "manager".

You might want to call this when you program first starts up to make the first
access a bit faster, or if you need to read back configuration settings before
looking up words.

The creation of the spelling manager builds a configuration
profile in the manager structure. Results from calling print_config() and get_option() will
change after calling create_manager().  In general, it's best to read config settings back
after calling create_manager() or after calling spell() or suggest().
Returns C<undef> on error, and the error message can be printed with $speller->errstr.

=item $speller->add_to_session($word)

=item $speller->add_to_personal($word)

Adds a word to the session or personal word lists.
Words added will be offered as suggestions.

=item $speller->store_replacement($word, $replacement);

This method can be used to instruct the speller which word you used as a replacement
for a misspelled word.  This allows the speller to offer up the replacement next time
the word is misspelled.  See section 4.7 of the Pspell documentation for a better description.

=item $speller->save_all_word_lists;

Writes any pending word lists to disk.

=item $speller->clear_session;

Clears the current session word list.


=back


=head2 EXPORT

None by default.

=head1 BUGS

Probably.


=head1 COPYRIGHT

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.


=head1 AUTHOR

Bill Moseley moseley@hank.org.

This module is based on a perl module written by Doru Theodor Petrescu <pdoru@kappa.ro>.

Aspell and Pspell are written and maintained by Kevin Atkinson.

Please see:

    http://aspell.sourceforge.net
    http://pspell.sourceforge.net


=cut
