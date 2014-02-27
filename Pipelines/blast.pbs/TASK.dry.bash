
[[ "$QUEUE" == "" ]] && echo "Undefined QUEUE" >&2 && exit 1;
[[ "$MAX_JOBS" == "" ]] && echo "Undefined MAX_JOBS" >&2 && exit 1;
[[ "$PPN" == "" ]] && echo "Undefined PPN" >&2 && exit 1;
[[ "$RAM" == "" ]] && echo "Undefined RAM" >&2 && exit 1;
[[ "$SCRATCH_DIR" == "" ]] && echo "Undefined SCRATCH_DIR" >&2 && exit 1;
[[ "$INPUT" == "" ]] && echo "Undefined INPUT" >&2 && exit 1;
[[ "$DB" == "" ]] && echo "Undefined DB" >&2 && exit 1;
[[ "$PROGRAM" == "" ]] && echo "Undefined PROGRAM" >&2 && exit 1;
[[ "$MAX_TRIALS" == "" ]] && echo "Undefined MAX_TRIALS" >&2 && exit 1;
[[ "$(type -t BEGIN)" == "function" ]] || ( echo "Undefined function BEGIN" && exit 1 ) ;
[[ "$(type -t BEFORE_BLAST)" == "function" ]] || ( echo "Undefined function BEFORE_BLAST" && exit 1 ) ;
[[ "$(type -t RUN_BLAST)" == "function" ]] || ( echo "Undefined function RUN_BLAST" && exit 1 ) ;
[[ "$(type -t AFTER_BLAST)" == "function" ]] || ( echo "Undefined function AFTER_BLAST" && exit 1 ) ;
[[ "$(type -t END)" == "function" ]] || ( echo "Undefined function END" && exit 1 ) ;

