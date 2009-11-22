# $Id$

# Test bf interpreter
# Print TAP, Test Anything Protocol

.sub 'main' :main
    $S0 = 'parrot -r bfco.pbc test.bf'
    $I0 = spawnw $S0
.end

