# $Id$

# Test bf compiler
# Print TAP, Test Anything Protocol

.sub 'main' :main
    $S0 = 'parrot -r bf.pbc test.bf'
    $I0 = spawnw $S0
.end

