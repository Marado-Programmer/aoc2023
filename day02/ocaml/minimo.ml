open Printf

let read_whole_chan chan =
  let buf = Buffer.create 4096 in
  let rec loop () =
    let line = input_line chan in
      Buffer.add_string buf line;
      Buffer.add_char buf '\n';
      loop ()
  in
    try loop () with
      End_of_file -> Buffer.contents buf

let read_whole_file filename =
  let chan = open_in filename in
    read_whole_chan chan

type rgb = int * int * int

let max_red = 12
let max_green = 13
let max_blue = 14

let sub sep = String.sub sep 1 ((String.length sep) - 1)

type split_marker =
  | KeepSpliting of string
  | Ignore of string
let split_on_string sep s : string list =
  let rec join_wrongs sep pieces correct =
    let s = sub sep in
    match pieces with
    | [] -> List.rev correct
    | x :: rest ->
      (if String.starts_with x ~prefix: s then
        KeepSpliting x :: correct
      else
        match correct with | [] -> [Ignore x] | y :: others -> (match y with
          | KeepSpliting y -> KeepSpliting (y ^ String.make 1 sep.[0] ^ x)
          | Ignore  y ->  Ignore (y ^ String.make 1 sep.[0] ^ x))
          :: others)
      |> join_wrongs sep rest in

  let rec split' sep pieces verified =
    if String.length sep = 0 then pieces
    else match pieces with
          | [] -> let s = sub sep in split' s (verified) []
          | x :: rest -> List.concat [verified; (match x with
            | KeepSpliting x ->
                let divided = String.split_on_char sep.[0] x in
                join_wrongs sep divided []
            | Ignore _ ->
              [x]
            )] |> split' sep rest in

  let slices = split' sep [KeepSpliting s] [] in

  let rec to_strs enum strs = match enum with
    | [] -> strs
    | x :: rest -> to_strs rest ((match x with
        | KeepSpliting y -> y
        | Ignore y -> y) :: strs) in

  to_strs slices [] |> List.rev
;;

let parse_game game : ((int * rgb list), _) result =
  match split_on_string ": " game with
  | game :: subsets :: [] -> Ok ( 0, [] )
  | _ -> Error ()
;;

let process_game game : int =
  match parse_game game with
  | Ok (id, subsets) -> id
  | Error _ -> 0
;;

let part1 lines : int =
    let rec loop acc ls = match ls with
      | [] -> 0
      | x :: rest -> loop (acc + process_game x) rest in
    loop 0 lines
;;

let () =
  let filename = Sys.argv.(1) in
  let lines = read_whole_file filename
              |> String.split_on_char '\n' in
  print_endline @@ string_of_int @@ part1 lines;
  (* print_endline @@ string_of_int @@ part2 lines; *)
;;
