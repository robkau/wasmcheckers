(module
  ;; Import functions from host to notify on game events
  ;;(import "events" "piecemoved"
  ;;  (func $notify_piecemoved (param $fromX i32) (param $fromY i32) (param $toX i32) (param $toY i32)))
  ;;
  ;;(import "events" "piececrowned"
  ;;    (func $notify_piececrowned (param $pieceX i32) (param $pieceY i32)))


  ;; Checkers board represented as 1d array of 64 cells (8x8 board dimensions)
  ;; Request at least one 64kB page (more than enough for board)
  (memory $mem 1)

  ;; Track player 1 turn or player 2 turn
  (global $currentTurn (mut i32) (i32.const 0))

  ;; A checkers piece is represented by i32 bit flag:
  ;; [unused 24 bits]00000000 - unoccupied square
  ;; [unused 24 bits]00000001 - black piece
  ;; [unused 24 bits]00000010 - white piece
  ;; [unused 24 bits]00000100 - crowned piece
  (global $WHITE i32 (i32.const 2))
  (global $BLACK i32 (i32.const 1))
  (global $CROWN i32 (i32.const 4))

  ;; Index = (x + (y*8))
  ;; Calculate array index via xy coordinates (Checkerboard is 8 squares wide)
  (func $indexAt (param $x i32) (param $y i32) (result i32)
    (i32.add
      (i32.mul
        (i32.const 8)
        (get_local $y)
      )
      (get_local $x)
    )
  )

  ;; Offset = Index * 4
  ;; Calculate byte offset via array index. (Each array item is 4 bytes of data)
  (func $offsetAt (param $x i32) (param $y i32) (result i32)
    (i32.mul
      (call $indexAt (get_local $x) (get_local $y))
      (i32.const 4)
    )
  )

  ;; Determine if a piece has been crowned
  (func $isCrowned (param $piece i32) (result i32)
    (i32.eq
      (i32.and (get_local $piece) (get_global $CROWN))
      (get_global $CROWN)
    )
  )

  ;; Determine if a piece is white
  (func $isWhite (param $piece i32) (result i32)
    (i32.eq
      (i32.and (get_local $piece) (get_global $WHITE))
      (get_global $WHITE)
    )
  )

  ;; Determine if a piece is black
  (func $isBlack (param $piece i32) (result i32)
    (i32.eq
      (i32.and (get_local $piece) (get_global $BLACK))
      (get_global $BLACK)
    )
  )

  ;; Add crown to a piece (no mutation of original)
  (func $withCrown (param $piece i32) (result i32)
    (i32.or (get_local $piece) (get_global $CROWN))
  )

  ;; Remove crown from a piece (no mutation of original)
  (func $withoutCrown (param $piece i32) (result i32)
    (i32.and (get_local $piece) (i32.const 3))
  )

  ;; Set a piece on the board
  (func $setPiece (param $x i32) (param $y i32) (param $piece i32)
    (i32.store
      (call $offsetAt
        (get_local $x)
        (get_local $y)
      )
      (get_local $piece)
    )
  )

  ;; Get a piece from the board
  (func $getPiece (param $x i32) (param $y i32) (result i32)
    (if (result i32)
      (block (result i32)
        ;; verify index is in range
        (i32.and
          (call $inRange
            (i32.const 0)
            (i32.const 7)
            (get_local $x)
          )
          (call $inRange
            (i32.const 0)
            (i32.const 7)
            (get_local $y)
          )
        )
      )
    (then
      ;; get piece from memory
      (i32.load
        (call $offsetAt
          (get_local $x)
          (get_local $y)
        )
      )
    )
    (else
      ;; trap out-of-bounds memory access
      (unreachable)
    )
    )
  )

  ;; Detect if values are within range of checkerboard
  (func $inRange (param $low i32) (param $high i32) (param $value i32) (result i32)
    (i32.and
      (i32.ge_s (get_local $value) (get_local $low))
      (i32.le_s (get_local $value) (get_local $high))
    )
  )



  ;;;; Helpers for tracking/setting current turn ;;;;
  ;; Get whos turn it is
  (func $getTurnOwner (result i32)
    (get_global $currentTurn)
  )

  ;; After turn ends, switch to other player
  (func $toggleTurnOwner
    (if (i32.eq (call $getTurnOwner) (get_global $BLACK))
      (then (call $setTurnOwner (get_global $WHITE)))
      (else (call $setTurnOwner (get_global $BLACK)))
    )
  )

  ;; Set turn owner
  (func $setTurnOwner (param $piece i32)
    (set_global $currentTurn (get_local $piece))
  )

  ;; Determine if it's a players turn
  (func $isPlayersTurn (param $player i32) (result i32)
    (i32.gt_s
      (i32.and (get_local $player) (call $getTurnOwner))
      (i32.const 0)
    )
  )


  ;; Helpers for performing moves and game rules
  (func $shouldCrown (param $pieceY i32) (param $piece i32) (result i32)
    (i32.or
      (i32.and
        (i32.eq
          (get_local $pieceY)
          (i32.const 0)
        )
        (call $isBlack (get_local $piece))
      )
      (i32.and
        (i32.eq
          (get_local $pieceY)
          (i32.const 7)
        )
        (call $isWhite (get_local $piece))
      )
    )
  )

  (func $crownPiece (param $x i32) (param $y i32)
    ;; retrieve piece
    (local $piece i32)
    (set_local $piece (call $getPiece (get_local $x) (get_local $y)))
    ;; crown it and set it
    (call $setPiece (get_local $x) (get_local $y) (call $withCrown (get_local $piece)))
    ;; dispatch event to host
    ;; todo (call $notify_piececrowned (get_local $x) (get_local $y))
  )

  (func $distance (param $x i32) (param $y i32) (result i32)
    (i32.sub (get_local $x) (get_local $y))
  )

  ;; todo me
  ;;(func $isValidMove (param $fromX i32) (param $fromY i32)
  ;;                   (param $toX i32) (param $toY i32) (result i32)
  ;;  (local $player i32)
  ;;  (local $target i32)
;;
  ;;  (set_local $player (call $getPiece (get_local $fromX) (get_local $fromY)))
  ;;  (set_local $target (call $getPiece (get_local $toX) (get_local $toY)))
  ;;)

  (export "offsetAt" (func $offsetAt))
  (export "isCrowned" (func $isCrowned))
  (export "isWhite" (func $isWhite))
  (export "isBlack" (func $isBlack))
  (export "withCrown" (func $withCrown))
  (export "withoutCrown" (func $withoutCrown))
  (export "inRange" (func $inRange))
)