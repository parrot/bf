#! /usr/local/bin/parrot
# Copyright (C) 2009, Parrot Foundation.
# $Id$

=head1 NAME

setup.pir - Python distutils style

=head1 DESCRIPTION

No Configure step, no Makefile generated.

=head1 USAGE

    $ parrot setup.pir build
    $ parrot setup.pir test
    $ sudo parrot setup.pir install

=cut

.sub 'main' :main
    .param pmc args
    $S0 = shift args
    load_bytecode 'distutils.pbc'

    $P0 = new 'Hash'
    $P0['name'] = 'bf'
    $P0['abstract'] = 'Brainfuck'
    $P0['description'] = 'This is a Brainfuck interpreter for Parrot.'
    $P0['license_type'] = 'Artistic License 2.0'
    $P0['license_uri'] = 'http://www.perlfoundation.org/artistic_license_2_0'
    $P0['copyright_holder'] = 'Parrot Foundation'
    $P0['generated_by'] = 'Francois Perrad <francois.perrad@gadz.org>'
    $P0['checkout_uri'] = 'https://svn.parrot.org/languages/bf/trunk'
    $P0['browser_uri'] = 'https://trac.parrot.org/languages/browser/bf'
    $P0['project_uri'] = 'https://trac.parrot.org/parrot/wiki/Languages'

    # build
    $P1 = new 'Hash'
    $P1['bf.pbc'] = 'bf.pasm'
    $P1['bfc.pbc'] = 'bfc.pir'
    $P1['bfco.pbc'] = 'bfco.pir'
    $P0['pbc_pir'] = $P1

    $P2 = new 'Hash'
    $P2['parrot-bf'] = 'bf.pbc'
    $P2['parrot-bfc'] = 'bfc.pbc'
    $P2['parrot-bfco'] = 'bfco.pbc'
    $P0['installable_pbc'] = $P2

    # test
    $S0 = get_parrot()
    $P0['prove_exec'] = $S0

    .tailcall setup(args :flat, $P0 :flat :named)
.end

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
