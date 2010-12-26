# $Id$
# A Brainfuck compiler
# By Leon Brocard <acme@astray.com>
#
# See http://www.catseye.mb.ca/esoteric/bf/
# for more information on this silly language

.loadlib 'io_ops'

.sub _main
  .param pmc argv
  .local int pc
  .local int maxpc
  .local int label
  .local string labelstr
  .local pmc code
  .local string filename
  .local string file
  .local string line
  .local string program
  .local string char

  program = argv[0]
  # check argc
  $I0 = argv
  if $I0 < 2 goto usage
  # Get the filename
  filename = argv[1]
  if filename goto SOURCE
usage:
  print "usage: ../../parrot "
  print program
  print " file.bf\n"
  end

  # Read the file into S1
SOURCE:
  open $P1, filename, 'r'
  defined $I0, $P1
  if $I0, SOURCE_LOOP
  print filename
  print " not found\n"
  branch usage
SOURCE_LOOP:
  read line, $P1, 1024
  file = file . line
  if line goto SOURCE_LOOP
  close $P1

  length maxpc, file

  # Initialise
  code = new 'StringBuilder'
  push code, "set I0, 0          # pc\n"
  # concat code, "trace 1\n"
  push code,  "new P0, 'ResizableIntegerArray' # memory\n"
  # this array doesn't support negative indices properly
  # start with some offset
  push code,  "set I1, 256          # pointer\n"
  push code,  "getstdout P30\n"
  push code,  "#pop S0, P30\n        # unbuffer\n"
  push code,  "getstdin P30\n"

  pc    = 0    # pc
  label = 0    # label count

  # The main compiler loop
INTERP:
  substr char, file, pc, 1
  push code,  "\nSTEP"
  labelstr = pc
  push code,  labelstr
  push code,  ": # "
  push code,  char
  push code,  "\n"

  if char != "+" goto NOTPLUS
  .local int n_plus
  null n_plus
  $I0 = pc + 1
plus_loop:
  inc n_plus
  if $I0 == maxpc goto emit_plus
  substr char, file, $I0, 1
  if char != "+" goto emit_plus
  inc $I0
  goto plus_loop
emit_plus:
  pc = $I0 - 1
  push code,  "set I2, P0[I1]\n"
  push code,  "add I2, "
  $S0 = n_plus
  push code,  $S0
  push code,  "\n"
  push code,  "band I2, 0xff\n"
  push code,  "set P0[I1], I2\n"
  goto NEXT

NOTPLUS:
  if char != "-" goto NOTMINUS
  .local int n_minus
  null n_minus
  $I0 = pc + 1
minus_loop:
  inc n_minus
  if $I0 == maxpc goto emit_minus
  substr char, file, $I0, 1
  if char != "-" goto emit_minus
  inc $I0
  goto minus_loop
emit_minus:
  pc = $I0 - 1
  push code,  "set I2, P0[I1]\n"
  push code,  "sub I2, "
  $S0 = n_minus
  push code,  $S0
  push code,  "\n"
  push code,  "band I2, 0xff\n"
  push code,  "set P0[I1], I2\n"
  goto NEXT

NOTMINUS:
  if char != ">" goto NOTGT
  .local int n_gt
  null n_gt
  $I0 = pc + 1
gt_loop:
  inc n_gt
  if $I0 == maxpc goto emit_gt
  substr char, file, $I0, 1
  if char != ">" goto emit_gt
  inc $I0
  goto gt_loop
emit_gt:
  pc = $I0 - 1
  push code,  "add I1, "
  $S0 = n_gt
  push code,  $S0
  push code,  "\n"
  goto NEXT

NOTGT:
  if char != "<" goto NOTLT
  .local int n_lt
  null n_lt
  $I0 = pc + 1
lt_loop:
  inc n_lt
  if $I0 == maxpc goto emit_lt
  substr char, file, $I0, 1
  if char != "<" goto emit_lt
  inc $I0
  goto lt_loop
emit_lt:
  pc = $I0 - 1
  push code,  "sub I1, "
  $S0 = n_lt
  push code,  $S0
  push code,  "\n"
  goto NEXT

NOTLT:
  if char != "[" goto NOTOPEN

  .local int depth

  label = pc
OPEN_LOOP:
  inc label
  substr $S2, file, label, 1
  if $S2 != "[" goto OPEN_NOTOPEN
  inc depth
  goto OPEN_LOOP
OPEN_NOTOPEN:
  if $S2 != "]" goto OPEN_LOOP
  if depth == 0 goto OPEN_NEXT
  dec depth
  goto OPEN_LOOP
OPEN_NEXT:
  inc label
  labelstr = label
  push code,  "set I2, P0[I1]\n"
  push code,  "unless I2, STEP"
  push code,  labelstr
  push code,  "\n"

  goto NEXT

NOTOPEN:
  if char != "]" goto NOTCLOSE

  label = pc
  depth = 0 # "height"

CLOSE_LOOP:
  dec label
  substr $S2, file, label, 1
  if $S2 != "]" goto CLOSE_NOTCLOSE
  inc depth
  goto CLOSE_LOOP
CLOSE_NOTCLOSE:
  if $S2 != "[" goto CLOSE_LOOP
  if depth == 0 goto CLOSE_NEXT
  dec depth
  goto CLOSE_LOOP

CLOSE_NEXT:
  labelstr = label
  push code,  "branch STEP"
  push code,  labelstr
  push code,  "\n"

  goto NEXT

NOTCLOSE:
  if char != "." goto NOTDOT
  push code,  "set I2, P0[I1]\n"
  push code,  "chr S31, I2\n"
  push code,  "print S31\n"
  goto NEXT

NOTDOT:
  if char != "," goto NEXT
  labelstr = pc
  push code,  "read S31, P30, 1\n"
  push code,  "if S31, no_eof"
  push code,  labelstr
  push code,  "\n"
  push code,  "null I2\n"
  push code,  "branch eof"
  push code,  labelstr
  push code,  "\n"
  push code,  "no_eof"
  push code,  labelstr
  push code,  ":\n"
  push code,  "ord I2, S31\n"
  push code,  "eof"
  push code,  labelstr
  push code,  ":\n"
  push code,  "set P0[I1], I2\n"
  goto NEXT

NEXT:
  inc pc

  if pc < maxpc goto INTERP
  labelstr = pc
  push code,  "STEP"
  push code,  labelstr
  push code,  ":\n"
  push code,  "end\n"

  # printerr code
  # printerr "\n"

  # Now actually run it
  compreg $P1, "PASM"
  $P0 = $P1( code )
  $P0()
.end

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
